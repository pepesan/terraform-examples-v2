output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

# sensitive oculta el valor en logs y plan, pero no lo cifra en el state.
# Para verlo: terraform output k8s_cluster_certificate_authority_data
output "k8s_cluster_certificate_authority_data" {
  value     = base64decode(module.eks.cluster_certificate_authority_data)
  sensitive = true
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

locals {
  alb_hostname = try(kubernetes_ingress_v1.blog.status[0].load_balancer[0].ingress[0].hostname, "pendiente")
}

output "service_urls" {
  description = "URLs de todos los servicios expuestos por el ALB"
  value = {
    headlamp = "http://${local.alb_hostname}/headlamp/"
    blog = "http://${local.alb_hostname}/"
  }
}