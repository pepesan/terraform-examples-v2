# Máquinas: una instancia de OVH Public Cloud por cada nombre de var.nodes
# (Ubuntu 26.04, flavor c3-16 por defecto), todas con la misma clave SSH, IP
# pública y nginx instalado por cloud-init.
#
# El resto de componentes está en: provider.tf (provider), variables.tf
# (entradas), dns.tf (un registro DNS por nodo) y outputs.tf (salidas).
# ATENCIÓN: crea N instancias reales con coste por hora cada una; hacer
# terraform destroy al terminar.

# --- Catálogo de la región (solo lectura, común a todos los nodos) ---

# Flavors de la región filtrados por nombre; sirve para traducir el nombre
# (c3-16) al id interno que exige la API.
data "ovh_cloud_project_flavors" "selected" {
  service_name = var.ovh_public_cloud_project_id
  region       = var.region
  name_filter  = var.flavor_name
}

# Imágenes Linux disponibles en la región, para traducir el nombre al id
data "ovh_cloud_project_images" "available" {
  service_name = var.ovh_public_cloud_project_id
  region       = var.region
  os_type      = "linux"
}

# Resuelve nombre -> id comparando el nombre exacto. Si no hay coincidencia,
# la precondition de la instancia falla con un mensaje claro.
locals {
  flavor_matches = [for f in data.ovh_cloud_project_flavors.selected.flavors : f.id if f.name == var.flavor_name]
  image_matches  = [for i in data.ovh_cloud_project_images.available.images : i.id if i.name == var.image_name]

  # Vacío si no hay coincidencia: la precondition de la instancia da entonces
  # un mensaje claro en vez de un "Invalid index"
  flavor_id = try(local.flavor_matches[0], "")
  image_id  = try(local.image_matches[0], "")

  # Los nodos como conjunto: la clave de cada instancia es su nombre
  nodes = toset(var.nodes)
}

# --- Recursos ---

# Una única clave SSH compartida por todos los nodos: se crea antes que las
# instancias y se borra en el destroy.
resource "ovh_cloud_project_ssh_key" "key" {
  service_name = var.ovh_public_cloud_project_id
  name         = var.ssh_key_name
  public_key   = file(var.ssh_public_key_path)
}

# Una instancia por nodo. for_each indexa por nombre: ovh_cloud_project_instance.vm["nodo01"]
resource "ovh_cloud_project_instance" "vm" {
  for_each = local.nodes

  service_name   = var.ovh_public_cloud_project_id
  region         = var.region
  name           = each.key
  billing_period = "hourly" # facturación por hora, sin compromiso

  # Tamaño de la máquina (vCPU/RAM/disco raíz fijos por flavor)
  flavor {
    flavor_id = local.flavor_id
  }

  # Imagen del sistema operativo con la que arranca
  boot_from {
    image_id = local.image_id
  }

  # Referencia por nombre la clave SSH creada arriba (usuario por defecto:
  # ubuntu). Usar el atributo del recurso crea la dependencia.
  ssh_key {
    name = ovh_cloud_project_ssh_key.key.name
  }

  # Comprueba, ya en el plan, que el flavor y la imagen existen en la región
  lifecycle {
    precondition {
      condition     = length(local.flavor_matches) > 0
      error_message = "El flavor '${var.flavor_name}' no existe en la región ${var.region}. Consulta el catálogo (ver README) y ajusta flavor_name."
    }
    precondition {
      condition     = length(local.image_matches) > 0
      error_message = "La imagen '${var.image_name}' no existe en la región ${var.region}. Consulta el catálogo (ver README) y ajusta image_name."
    }
  }

  # IP pública fija mientras exista la instancia (puede cambiar si se
  # destruye y se vuelve a crear)
  network {
    public = true
  }

  # Backup automático (snapshot) del disco raíz de cada nodo. Con
  # backup_enabled = false el bloque desaparece.
  dynamic "auto_backup" {
    for_each = var.backup_enabled ? [1] : []
    content {
      cron     = var.backup_cron
      rotation = var.backup_rotation
    }
  }

  # cloud-init del primer arranque (ver cloud-init.yaml.tftpl): instala nginx
  # y publica un index.html que identifica el nodo. Cambiarlo obliga a
  # recrear la instancia, porque cloud-init solo se ejecuta al crearla.
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    fqdn          = "${each.key}.${var.domain}"
    instance_name = each.key
    flavor_name   = var.flavor_name
  })
}

# Primera IPv4 de cada instancia, por nodo (la usan dns.tf y outputs.tf)
locals {
  public_ips = {
    for name, vm in ovh_cloud_project_instance.vm :
    name => [for a in vm.addresses : a.ip if a.version == 4][0]
  }
}
