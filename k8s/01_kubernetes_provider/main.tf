variable "k8s_host" {}
variable "k8s_token" {}
variable "k8s_ca_cert" {}

provider "kubernetes" {
  host = var.k8s_host
  token = var.k8s_token
  cluster_ca_certificate = base64decode(var.k8s_ca_cert)
  load_config_file = false
}

data "kubernetes_all_namespaces" "allns" {}

output "all-ns" {
  value = data.kubernetes_all_namespaces.allns.namespaces
}
