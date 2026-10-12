# Salidas del ejemplo (terraform output).

# Un objeto por nodo, indexado por su nombre:
#   terraform output -json nodes | jq -r '.nodo01.ssh_connection'
output "nodes" {
  description = "Datos de cada nodo: nombre DNS, IP, conexión SSH y URL web"
  value = {
    for name, n in module.node : name => {
      fqdn        = n.fqdn
      instance_id = n.instance_id
      public_ip   = n.public_ip
      flavor      = lookup(var.node_flavors, name, var.flavor_name)
      # Clave privada = la pública sin ".pub"; usuario por defecto: ubuntu
      ssh_connection = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${n.public_ip}"
      web_url        = n.web_url
      dns_record_id  = n.dns_record_id
    }
  }
}

output "fqdns" {
  value = sort([for n in module.node : n.fqdn])
}

# Contenido del CSV ip,fqdn (el mismo que se escribe en inventory_csv_path):
#   terraform output -raw inventory_csv
output "inventory_csv" {
  description = "CSV con una fila ip,fqdn por nodo"
  value       = local_file.inventory_csv.content
}

output "inventory_csv_path" {
  description = "Ruta absoluta del fichero CSV generado"
  value       = abspath(local_file.inventory_csv.filename)
}
