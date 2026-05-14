# ─── Providers ───────────────────────────────────────────────────────────────

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
    }
  }
}

# ─── IAM para AWS Load Balancer Controller ────────────────────────────────────

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${local.cluster_name}"
  policy = file("${path.module}/iam/iam_policy.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "AWSLoadBalancerControllerRole-${local.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" } # Pod Identity usa este principal; IRSA usa el OIDC provider
      Action    = ["sts:AssumeRole", "sts:TagSession"]   # Pod Identity requiere TagSession además de AssumeRole; IRSA no lo necesita
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.alb_controller.arn

  depends_on = [module.eks]
}

# ─── AWS Load Balancer Controller (Helm) ─────────────────────────────────────

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "3.3.0"

  set = [
    { name = "clusterName", value = local.cluster_name },
    { name = "serviceAccount.create", value = "true" },
    { name = "region", value = var.region },
    { name = "vpcId", value = module.vpc.vpc_id },
  ]

  wait    = true # espera a que el pod esté Ready antes de continuar; sin esto el Ingress se crea antes de que el controller esté operativo
  timeout = 300
  # comentado esta dependencias por error ciclico: time_sleep.wait_alb_cleanup
  depends_on = [aws_eks_pod_identity_association.alb_controller]
}

# ─── Espera a que el ALB Controller limpie los ALBs y SGs antes del destroy ───

resource "time_sleep" "wait_alb_cleanup" {
  depends_on = [kubernetes_ingress_v1.headlamp, kubernetes_ingress_v1.nginx_app]
  # en destroy espera 60s para que el ALB Controller elimine el ALB y sus SGs
  # antes de que Terraform continúe borrando el cluster y el VPC
  destroy_duration = "60s"
}

# ─── Headlamp Dashboard ───────────────────────────────────────────────────────

resource "helm_release" "headlamp" {
  name       = "headlamp"
  repository = "https://kubernetes-sigs.github.io/headlamp/"
  chart      = "headlamp"
  namespace  = "kube-system"

  set = [
    { name = "config.baseURL", value = "/headlamp" },
  ]

  depends_on = [module.eks]
}

resource "kubernetes_ingress_v1" "headlamp" {
  metadata {
    name      = "headlamp"
    namespace = "kube-system"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"         # apunta al pod directamente; necesario para IngressGroup cross-namespace
      "alb.ingress.kubernetes.io/group.name"       = "eks-alb"    # IngressGroup: varios Ingress de distintos namespaces comparten un único ALB
      "alb.ingress.kubernetes.io/group.order"      = "1"          # orden de evaluación de reglas dentro del grupo; menor número = mayor prioridad
      "alb.ingress.kubernetes.io/healthcheck-path" = "/headlamp/" # la ruta "/" devuelve 404 en Headlamp, lo que marcaría los targets como unhealthy
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/headlamp"
          path_type = "Prefix"
          backend {
            service {
              name = "headlamp"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.alb_controller, helm_release.headlamp, module.eks]
}

# ─── Aplicación nginx ─────────────────────────────────────────────────────────

# El ALB Controller crea TargetGroupBindings en este namespace con finalizers que
# solo él puede eliminar. Si el controller ya no existe al borrar el namespace,
# los finalizers bloquean el destroy. Este null_resource los limpia antes.
resource "null_resource" "cleanup_nginx_tgb" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl get targetgroupbindings -n nginx-app -o name 2>/dev/null | \
      xargs -r -I {} kubectl patch {} -n nginx-app \
        -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
    EOT
  }
}

resource "kubernetes_namespace" "nginx_app" {
  metadata {
    name = "nginx-app"
  }
  depends_on = [module.eks, null_resource.cleanup_nginx_tgb]
}

resource "kubernetes_deployment" "nginx_app" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.nginx_app.metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "nginx" }
    }
    template {
      metadata {
        labels = { app = "nginx" }
      }
      spec {
        container {
          image = "nginx:1.27"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_app" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.nginx_app.metadata[0].name
  }
  spec {
    selector = { app = "nginx" }
    type     = "ClusterIP"
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "nginx_app" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.nginx_app.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip" # idem que headlamp: target-type ip para IngressGroup cross-namespace
      "alb.ingress.kubernetes.io/group.name"  = "eks-alb"
      "alb.ingress.kubernetes.io/group.order" = "2" # prioridad 2: nginx va después de headlamp; la ruta "/" es el catch-all
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.nginx_app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.alb_controller, module.eks]
}