# Salidas del ejemplo (terraform output).

# --- DNS ---

# Nombre DNS completo de la máquina
output "fqdn" {
  value = "${var.hostname}.${var.domain}"
}

# Id numérico del registro en OVH (útil para terraform import o la API)
output "dns_record_id" {
  value = ovh_domain_zone_record.node.id
}

# --- Máquina ---

output "instance_id" {
  value = ovh_cloud_project_instance.vm.id
}

# Primera dirección IPv4 de la instancia, para conectarse por SSH
output "public_ip" {
  value = local.public_ip
}

# Comando listo para copiar y pegar. Usa la clave privada que corresponde a
# la pública indicada en ssh_public_key_path (misma ruta sin el ".pub") y el
# usuario por defecto de la imagen Ubuntu ("ubuntu").
output "ssh_connection" {
  value = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${local.public_ip}"
}

# URL de la web servida por nginx (tarda 1-2 minutos tras el apply en
# responder, mientras cloud-init instala nginx; con certbot_email, HTTPS
# tarda además unos minutos hasta que se obtiene el certificado)
output "web_url" {
  value = "${var.certbot_email != "" ? "https" : "http"}://${var.hostname}.${var.domain}"
}

# Ids internos a los que se han resuelto flavor_name e image_name
output "flavor_id_used" {
  value = local.flavor_id
}

output "image_id_used" {
  value = local.image_id
}
