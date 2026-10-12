# Módulo node: UNA instancia de OVH Public Cloud con nginx (cloud-init) y su
# registro A <name>.<domain> apuntando a su IP pública.
# ATENCIÓN: crea una instancia real con coste por hora.

# --- Catálogo de la región (solo lectura) ---

# Traduce el nombre del flavor (c3-16) al id interno que exige la API
data "ovh_cloud_project_flavors" "selected" {
  service_name = var.project_id
  region       = var.region
  name_filter  = var.flavor_name
}

# Imágenes Linux de la región, para traducir el nombre al id
data "ovh_cloud_project_images" "available" {
  service_name = var.project_id
  region       = var.region
  os_type      = "linux"
}

locals {
  flavor_matches = [for f in data.ovh_cloud_project_flavors.selected.flavors : f.id if f.name == var.flavor_name]
  image_matches  = [for i in data.ovh_cloud_project_images.available.images : i.id if i.name == var.image_name]

  # Vacío si no hay coincidencia: la precondition da entonces un mensaje claro
  flavor_id = try(local.flavor_matches[0], "")
  image_id  = try(local.image_matches[0], "")

  fqdn = "${var.name}.${var.domain}"
}

# --- Recursos ---

resource "ovh_cloud_project_instance" "vm" {
  service_name   = var.project_id
  region         = var.region
  name           = var.name
  billing_period = "hourly" # facturación por hora, sin compromiso

  flavor {
    flavor_id = local.flavor_id
  }

  boot_from {
    image_id = local.image_id
  }

  # Clave SSH existente en el proyecto (usuario por defecto: ubuntu)
  ssh_key {
    name = var.ssh_key_name
  }

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

  network {
    public = true
  }

  # Backup automático del disco raíz; con backup_enabled = false desaparece
  dynamic "auto_backup" {
    for_each = var.backup_enabled ? [1] : []
    content {
      cron     = var.backup_cron
      rotation = var.backup_rotation
    }
  }

  # cloud-init del primer arranque: instala nginx y publica un index.html que
  # identifica el nodo. Cambiarlo recrea la instancia.
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    fqdn          = local.fqdn
    instance_name = var.name
    flavor_name   = var.flavor_name
  })
}

locals {
  public_ip = [for a in ovh_cloud_project_instance.vm.addresses : a.ip if a.version == 4][0]
}

# El registro se crea tras conocer la IP y se actualiza si esta cambia
resource "ovh_domain_zone_record" "dns" {
  zone      = var.domain
  subdomain = var.name
  fieldtype = "A"
  ttl       = var.dns_ttl
  target    = local.public_ip
}
