variable "do_token" {}
variable "region" {}
variable "project_name" {}

provider "digitalocean" {
    token = var.do_token
}


resource "digitalocean_kubernetes_cluster" "cluster" {
    name    = "${var.project_name}-cluster"
    region  = var.region
    version = "1.18.6-do.0"
    tags    = ["testing"]
    node_pool {
        name       = "worker-pool"
        size       = "s-2vcpu-2gb"
        node_count = 1
    }
}
provider "kubernetes" {
    load_config_file = false
    host  = digitalocean_kubernetes_cluster.cluster.endpoint
    token = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
    )
}

output "cluster-id" {
    value = digitalocean_kubernetes_cluster.cluster.id
}
output "endpoint" {
    value = digitalocean_kubernetes_cluster.cluster.endpoint
}
output "token" {
    value = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
}

output "cert" {
    value = digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
}

