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
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
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
    { name = "clusterName",           value = local.cluster_name },
    { name = "serviceAccount.create", value = "true" },
    { name = "region",                value = var.region },
    { name = "vpcId",                 value = module.vpc.vpc_id },
  ]

  depends_on = [aws_eks_pod_identity_association.alb_controller]
}

# ─── Aplicación nginx ─────────────────────────────────────────────────────────

resource "kubernetes_namespace" "nginx_app" {
  metadata {
    name = "nginx-app"
  }
  depends_on = [module.eks]
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
      "alb.ingress.kubernetes.io/target-type" = "ip"
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
  depends_on = [helm_release.alb_controller]
}