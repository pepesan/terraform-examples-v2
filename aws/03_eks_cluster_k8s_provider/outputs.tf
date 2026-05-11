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

output "nginx_ingress_url" {
  description = "URL del ALB creado por el Ingress nginx (puede tardar ~2 min en estar disponible)"
  value       = "http://${try(kubernetes_ingress_v1.nginx_app.status[0].load_balancer[0].ingress[0].hostname, "pendiente")}"
}