# Ejemplo 06: lo mismo que el 05 (N máquinas con nginx y un registro DNS cada
# una), pero cada nodo es una llamada al módulo compartido ../modules/node.
# Aquí solo queda lo que es común a todos: la clave SSH y la lista de nodos.
# ATENCIÓN: crea N instancias reales con coste por hora; hacer terraform
# destroy al terminar.

# Una única clave SSH compartida por todos los nodos: se crea antes que las
# instancias y se borra en el destroy.
resource "ovh_cloud_project_ssh_key" "key" {
  service_name = var.ovh_public_cloud_project_id
  name         = var.ssh_key_name
  public_key   = file(var.ssh_public_key_path)
}

# Una llamada al módulo por nombre: module.node["nodo01"], module.node["nodo02"]...
# Quitar un nombre de la lista destruye solo ese módulo (instancia y registro).
module "node" {
  source   = "../modules/node"
  for_each = toset(var.nodes)

  project_id = var.ovh_public_cloud_project_id
  region     = var.region
  name       = each.key
  domain     = var.domain

  # Usar el atributo del recurso (no la variable) crea la dependencia: la
  # clave existe antes que cualquier instancia
  ssh_key_name = ovh_cloud_project_ssh_key.key.name

  # El flavor propio del nodo si lo tiene; si no, el común
  flavor_name = lookup(var.node_flavors, each.key, var.flavor_name)
  image_name  = var.image_name

  backup_enabled  = var.backup_enabled
  backup_cron     = var.backup_cron
  backup_rotation = var.backup_rotation
}

# Inventario ip,fqdn de los nodos: cabecera y una fila por nodo, ordenadas por
# nombre. Terraform no tiene función para escribir CSV, así que se arma con
# join; es seguro porque ni una IP ni un nombre DNS pueden llevar comas. El
# fichero se reescribe si cambia alguna IP y se borra en el destroy.
resource "local_file" "inventory_csv" {
  filename        = "${path.module}/${var.inventory_csv_path}"
  file_permission = "0644"
  content = join("\n", concat(
    ["ip,fqdn"],
    [for name in sort(keys(module.node)) : "${module.node[name].public_ip},${module.node[name].fqdn}"],
    [""] # salto de línea final
  ))
}
