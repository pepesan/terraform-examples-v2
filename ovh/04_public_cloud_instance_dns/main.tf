# Máquina: instancia de OVH Public Cloud (Ubuntu 26.04, flavor c3-16: 8 vCPU,
# 16 GB de RAM y 200 GB de disco raíz), con clave SSH inyectada, IP pública y
# nginx instalado por cloud-init. No lleva volumen adicional: los 200 GB son
# el propio disco raíz, así que las páginas web de nginx están en él.
#
# El resto de componentes está en: provider.tf (provider), variables.tf
# (entradas), dns.tf (registro DNS) y outputs.tf (salidas).
# ATENCIÓN: crea recursos reales con coste por hora; hacer terraform destroy.

# --- Catálogo de la región (solo lectura) ---

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
}

# --- Recursos ---

# Clave SSH como recurso independiente: se crea antes que la instancia, se
# borra en el destroy y se puede reutilizar en otras máquinas.
resource "ovh_cloud_project_ssh_key" "key" {
  service_name = var.ovh_public_cloud_project_id
  name         = "${var.instance_name}-key"
  public_key   = file(var.ssh_public_key_path)
}

resource "ovh_cloud_project_instance" "vm" {
  service_name   = var.ovh_public_cloud_project_id
  region         = var.region
  name           = var.instance_name
  billing_period = "hourly" # facturación por hora, sin compromiso

  # Tamaño de la máquina (vCPU/RAM/disco raíz fijos por flavor)
  flavor {
    flavor_id = local.flavor_id
  }

  # Imagen del sistema operativo con la que arranca
  boot_from {
    image_id = local.image_id
  }

  # Referencia por nombre la clave SSH creada arriba; se inyecta en la
  # instancia (usuario por defecto: ubuntu). Usar el atributo del recurso
  # (y no un texto fijo) crea la dependencia: la clave se crea antes.
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

  # Backup automático (snapshot) del disco raíz, gestionado por OVH. Con
  # backup_enabled = false el bloque desaparece. Como no hay volumen
  # adicional, cubre todo: sistema y páginas web.
  dynamic "auto_backup" {
    for_each = var.backup_enabled ? [1] : []
    content {
      cron     = var.backup_cron
      rotation = var.backup_rotation
    }
  }

  # cloud-init del primer arranque (ver cloud-init.yaml.tftpl): instala nginx,
  # publica un index.html que identifica el despliegue y, si certbot_email
  # no está vacío, pide un certificado TLS con certbot (obtener-
  # certificado.sh). Cambiarlo obliga a recrear la instancia, porque
  # cloud-init solo se ejecuta al crearla.
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    fqdn            = "${var.hostname}.${var.domain}"
    instance_name   = var.instance_name
    flavor_name     = var.flavor_name
    certbot_email   = var.certbot_email
    certbot_staging = var.certbot_staging
    certbot_script  = file("${path.module}/obtener-certificado.sh")
  })
}

# Primera IPv4 de la instancia (la usan dns.tf y outputs.tf)
locals {
  public_ip = [for a in ovh_cloud_project_instance.vm.addresses : a.ip if a.version == 4][0]
}
