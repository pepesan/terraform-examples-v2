# Ejemplo 03: instancia de OVH Public Cloud (Ubuntu 26.04, flavor c3-8) con
# un volumen adicional de 200 GB, clave SSH inyectada e IP pública.
# ATENCIÓN: crea recursos reales con coste por hora; hacer terraform destroy.

# --- Variables (sus valores van en terraform.tfvars, que no se versiona) ---

# Endpoint de la API según la cuenta: "ovh-eu", "ovh-us", "ovh-ca"...
# Si se omite (null), el provider usa la variable de entorno OVH_ENDPOINT.
variable "ovh_endpoint" {
  type    = string
  default = null
}

# Las tres credenciales se generan juntas al crear el token en createToken.
# El token necesita GET/POST/PUT/DELETE sobre /cloud/project/*.
# Las tres credenciales se pueden dar por variable de entorno en vez de por
# tfvars (OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET, OVH_CONSUMER_KEY).
variable "ovh_application_key" {
  type    = string
  default = null
}
variable "ovh_application_secret" {
  type      = string
  default   = null
  sensitive = true
}
variable "ovh_consumer_key" {
  type      = string
  default   = null
  sensitive = true
}

# Identificador del proyecto Public Cloud (el "service_name" de la API)
variable "ovh_public_cloud_project_id" {}

# Región donde se crea la instancia (p. ej. "GRA11"); el catálogo de
# flavors e imágenes depende de ella.
variable "region" {}

# Nombre de la instancia; también prefija la clave SSH y el volumen
variable "instance_name" {}

# Clave pública local que se inyecta en la instancia al crearla
variable "ssh_public_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

# Nombre exacto del flavor a usar (ver README: cómo se consigue este
# valor consultando el catálogo de la región).
variable "flavor_name" {
  default = "c3-8"
}

# Nombre exacto de la imagen a usar (ver README).
variable "image_name" {
  default = "Ubuntu 26.04"
}

# Tipo del volumen adicional. La API de OVH rechaza la creación si no se
# indica (400 "Invalid value(s) received: VolumeType"), aunque el provider
# lo marque como opcional. Los disponibles dependen de la región.
#
#   "classic"         Almacenamiento básico de rendimiento fijo y bajo
#                     (~500 IOPS y ~64 MB/s, no crece con el tamaño). Es el
#                     más barato: sirve para copias, datos poco accedidos.
#   "high-speed"      SSD de primera generación (Gen 1): hasta ~3.000 IOPS
#                     y ~128 MB/s. OVH ya no deja pedirlo desde el panel,
#                     pero sigue disponible por API/Terraform.
#   "high-speed-gen2" SSD de segunda generación: el rendimiento escala con
#                     el tamaño (30 IOPS y 0,5 MB/s por GB; mínimo 3.000
#                     IOPS y 50 MB/s, máximo 20.000 IOPS y 512 MB/s). Es el
#                     recomendado para bases de datos y cargas intensivas;
#                     no está en todas las regiones.
#
# Cifras orientativas de la documentación de OVH (Block Storage); pueden
# cambiar: consultar "Block Storage: elegir la clase de almacenamiento".
variable "volume_type" {
  default = "high-speed"
}

# Backup automático (snapshot periódico) del DISCO RAÍZ de la instancia,
# gestionado por OVH. No incluye el volumen adicional (donde viven las
# páginas web). Los snapshots se facturan por GB almacenado.
#
# OJO: añadir o quitar el bloque auto_backup FUERZA LA RECREACIÓN de la
# instancia (y con ella del volumen, que pierde sus datos), así que por
# defecto está desactivado para no tocar una máquina ya creada. Actívalo al
# crear la instancia, o asume la recreación.
variable "backup_enabled" {
  type        = bool
  description = "Activa el backup automático de la instancia (auto_backup); cambiarlo recrea la instancia"
  default     = false
}

# Formato cron de 5 campos: minuto hora día-del-mes mes día-de-la-semana.
# Ej.: "0 3 * * *" = todos los días a las 03:00; "0 3 * * 0" = domingos.
variable "backup_cron" {
  type        = string
  description = "Cuándo se hace el backup automático, en formato cron Unix"
  default     = "0 3 * * *"
}

variable "backup_rotation" {
  type        = number
  description = "Cuántos backups automáticos se conservan; al superarlo se borran los más antiguos"
  default     = 7

  validation {
    condition     = var.backup_rotation >= 1
    error_message = "backup_rotation debe ser al menos 1."
  }
}

# Directorio donde se monta el disco adicional. Por defecto es el
# directorio de las páginas web de nginx en Ubuntu, de modo que todo lo que
# se publique ahí queda en el volumen de 200 GB y no en el disco raíz.
variable "data_mount_point" {
  default = "/var/www/html"
}

# --- Provider ---

# Autenticación contra la API de OVH con el token (no con usuario/contraseña)
provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

# --- Catálogo de la región (solo lectura) ---

# Flavors de la región filtrados por nombre; sirve para traducir el nombre
# (c3-8) al id interno que exige la API.
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
  # backup_enabled = false el bloque desaparece. No cubre el volumen
  # adicional, donde están las páginas web.
  dynamic "auto_backup" {
    for_each = var.backup_enabled ? [1] : []
    content {
      cron     = var.backup_cron
      rotation = var.backup_rotation
    }
  }

  # cloud-init del primer arranque: instala nginx y monta el disco adicional
  # en data_mount_point. La config está en cloud-init.yaml.tftpl y el script
  # de montaje en montar-datos.sh, que se incrusta en ella. Cambiar
  # cualquiera de los dos obliga a recrear la instancia, porque cloud-init
  # solo se ejecuta al crearla.
  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    mount_point = var.data_mount_point
    script      = file("${path.module}/montar-datos.sh")
  })
}

# Disco adicional de 200GB: el disco raíz del flavor es fijo y pequeño.
# Se asocia a la instancia y aparece como un segundo disco sin montar.
resource "ovh_cloud_project_volume" "data" {
  service_name = var.ovh_public_cloud_project_id
  region_name  = var.region
  name         = "${var.instance_name}-data"
  size         = 200 # GB
  type         = var.volume_type
  instance_id  = ovh_cloud_project_instance.vm.id
}

# --- Outputs ---

# Primera IPv4 de la instancia (la usan public_ip y ssh_connection)
locals {
  public_ip = [for a in ovh_cloud_project_instance.vm.addresses : a.ip if a.version == 4][0]
}

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
# responder, mientras cloud-init instala nginx y monta el disco)
output "web_url" {
  value = "http://${local.public_ip}"
}

# Ids internos a los que se han resuelto flavor_name e image_name
output "flavor_id_used" {
  value = local.flavor_id
}

output "image_id_used" {
  value = local.image_id
}
