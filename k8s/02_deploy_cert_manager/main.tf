variable "k8s_host" {}
variable "k8s_token" {}
variable "k8s_ca_cert" {}
variable "lets_encrypt_email"{}
provider "helm" {
  kubernetes {
    host = var.k8s_host
    token = var.k8s_token
    cluster_ca_certificate = base64decode(var.k8s_ca_cert)
    load_config_file = false
    config_path = "ensure-that-we-never-read-kube-config-from-home-dir"
  }
}
provider "kubernetes" {
  host = var.k8s_host
  token = var.k8s_token
  cluster_ca_certificate = base64decode(var.k8s_ca_cert)
  load_config_file = false
}
provider "kubernetes-alpha" {
  host = var.k8s_host
  token = var.k8s_token
  cluster_ca_certificate = base64decode(var.k8s_ca_cert)
  server_side_planning = true
}

# Install Letsencrypt Certificate Manager
resource "helm_release" "cert_manager" {
  name              = "cert-manager"
  namespace         = "cert-manager"
  create_namespace  = true
  repository        = "https://charts.jetstack.io"
  chart             = "cert-manager"
  version           = "v0.16.1"
  set {
    name  = "installCRDs"
    value = true
  }
  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
}

#resource "kubernetes_manifest" "cert-manager-cluster-issuer" {
#  depends_on = [helm_release.cert_manager]
#  provider = kubernetes-alpha
#
#  manifest = {
#    "apiVersion" = "cert-manager.io/v1alpha2"
#    "kind" = "ClusterIssuer"
#    "metadata" = {
#      "name" = "letsencrypt-prod"
#    }
#    "spec" = {
#      "acme" = {
#        "email" = var.lets_encrypt_email
#        "privateKeySecretRef" = {
#          "name" = "letsencrypt-prod"
#        }
#        "server" = "https://acme-v02.api.letsencrypt.org/directory"
#        "solvers" = [
#          {
#            http01 = {
#              "ingress" = {
#                "class" = "nginx"
#                "podTemplate" = {
#                  "spec" = {
#                    "nodeSelector" = {
#                      "kubernetes.io/os" = "linux"
#                    }
#                  }
#                }
#              }
#            }
#          },
#        ]
#      }
#    }
#  }
#}

data "kubernetes_all_namespaces" "allns" {}

output "all-ns" {
  value = data.kubernetes_all_namespaces.allns.namespaces
}

data "kubernetes_service" "alls"{
  metadata {
    name = "cert-manager"
    namespace = "cert-manager"
  }
}

output "cm-spec" {
  value = data.kubernetes_service.alls.spec
}
output "cm-load_balancer_ingress" {
  value = data.kubernetes_service.alls.load_balancer_ingress
}

data "kubernetes_pod" "cert-manager" {
  metadata {
    name = "cert-manager"
    namespace = "cert-manager"
  }
}
#output "cm-pods" {
#  value = data.kubernetes_pod.cert-manager.
#}






