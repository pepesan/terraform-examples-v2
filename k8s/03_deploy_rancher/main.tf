variable "k8s_host" {}
variable "k8s_token" {}
variable "k8s_ca_cert" {}
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
resource "kubernetes_namespace" "rancher" {
  metadata {
    annotations = {
      name = "rancher"
    }

    labels = {
      namespace = "cattle-system"
    }

    name = "cattle-system"
  }
}

resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rancher"
  namespace = "cattle-system"
}


output "casandra-metadata" {
  value = helm_release.rancher.metadata
}

