output "fqdn" {
  description = "Nombre DNS completo del nodo"
  value       = local.fqdn
}

output "instance_id" {
  description = "Id de la instancia en OVH"
  value       = ovh_cloud_project_instance.vm.id
}

output "public_ip" {
  description = "Primera IPv4 pública de la instancia"
  value       = local.public_ip
}

output "web_url" {
  description = "URL del nginx (tarda 1-2 minutos tras el apply en responder)"
  value       = "http://${local.fqdn}"
}

output "dns_record_id" {
  description = "Id del registro A en la zona"
  value       = ovh_domain_zone_record.dns.id
}

output "flavor_id" {
  description = "Id interno al que se ha resuelto flavor_name"
  value       = local.flavor_id
}

output "image_id" {
  description = "Id interno al que se ha resuelto image_name"
  value       = local.image_id
}
