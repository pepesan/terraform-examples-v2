# Salidas del ejemplo (terraform output).

# Un objeto por nodo, indexado por su nombre. Ejemplos:
#   terraform output nodes
#   terraform output -json nodes | jq -r '.nodo01.ssh_connection'
output "nodes" {
  description = "Datos de cada nodo: nombre DNS, IP, conexión SSH y URL web"
  value = {
    for name, vm in ovh_cloud_project_instance.vm : name => {
      fqdn        = "${name}.${var.domain}"
      instance_id = vm.id
      public_ip   = local.public_ips[name]
      # Usa la clave privada que corresponde a la pública indicada en
      # ssh_public_key_path (misma ruta sin el ".pub") y el usuario por
      # defecto de la imagen Ubuntu ("ubuntu").
      ssh_connection = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${local.public_ips[name]}"
      # nginx tarda 1-2 minutos tras el apply en responder
      web_url       = "http://${name}.${var.domain}"
      dns_record_id = ovh_domain_zone_record.node[name].id
    }
  }
}

# Lista de nombres DNS completos, cómoda para scripts o inventarios
output "fqdns" {
  value = sort([for name in var.nodes : "${name}.${var.domain}"])
}

# Ids internos a los que se han resuelto flavor_name e image_name
output "flavor_id_used" {
  value = local.flavor_id
}

output "image_id_used" {
  value = local.image_id
}
