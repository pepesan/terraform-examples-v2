# Variables de entrada. Sus valores van en terraform.tfvars, que no se
# versiona (ver terraform.tfvars.example).

# --- Acceso a la API de OVH ---

variable "ovh_endpoint" {
  type        = string
  description = "Endpoint de la API según la cuenta: ovh-eu, ovh-us, ovh-ca..."
  default     = null
}

# Las credenciales se pueden dar por tfvars o por variables de entorno
# (OVH_ENDPOINT, OVH_APPLICATION_KEY, OVH_APPLICATION_SECRET,
# OVH_CONSUMER_KEY): con el valor por defecto null, el provider las lee del
# entorno. Se generan juntas al crear el token en createToken.
# El token necesita GET/POST/PUT/DELETE sobre /cloud/project/* (instancia) y
# sobre /domain/zone/* (registro DNS).
variable "ovh_application_key" {
  type        = string
  description = "Application Key del token de la API de OVH"
  default     = null
}

variable "ovh_application_secret" {
  type        = string
  description = "Application Secret del token de la API de OVH"
  default     = null
  sensitive   = true
}

variable "ovh_consumer_key" {
  type        = string
  description = "Consumer Key del token de la API de OVH"
  default     = null
  sensitive   = true
}

variable "ovh_public_cloud_project_id" {
  type        = string
  description = "Identificador del proyecto Public Cloud (el service_name de la API)"
}

# --- Instancia ---

variable "region" {
  type        = string
  description = "Región donde se crea la instancia (p. ej. GRA11); el catálogo de flavors e imágenes depende de ella"
}

# OJO: cambiarlo recrea la instancia y el volumen (el nombre no es
# modificable in situ), así que es independiente del nombre DNS (hostname).
variable "instance_name" {
  type        = string
  description = "Nombre de la instancia; también prefija la clave SSH y el volumen"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Clave pública local que se inyecta en la instancia al crearla"
  default     = "~/.ssh/id_ed25519.pub"
}

# c3-16: 8 vCPU, 16 GB de RAM y 200 GB de disco raíz (por eso no hay
# volumen adicional). Ver README: cómo se consigue este valor consultando
# el catálogo de la región.
variable "flavor_name" {
  type        = string
  description = "Nombre exacto del flavor a usar"
  default     = "c3-16"
}

variable "image_name" {
  type        = string
  description = "Nombre exacto de la imagen a usar"
  default     = "Ubuntu 26.04"
}

# --- Certificado TLS (certbot / Let's Encrypt) ---

# Si se indica, cloud-init instala certbot y pide un certificado para
# <hostname>.<domain>, configurando nginx con HTTPS y redirección desde HTTP.
# Si se deja vacío no se instala ni se pide nada (solo HTTP). Requisitos: que
# el dominio esté delegado públicamente (la validación es por HTTP desde
# Internet) y los puertos 80 y 443 abiertos.
variable "certbot_email" {
  type        = string
  description = "Correo para Let's Encrypt; si está vacío no se pide certificado"
  default     = ""

  validation {
    condition     = var.certbot_email == "" || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.certbot_email))
    error_message = "certbot_email debe estar vacío o ser un correo válido."
  }
}

# Let's Encrypt limita los intentos fallidos y los certificados duplicados
# por semana. Con true se usa el entorno de pruebas: el certificado no lo
# aceptan los navegadores, pero permite ensayar sin gastar el límite real.
variable "certbot_staging" {
  type        = bool
  description = "Usa el entorno de pruebas de Let's Encrypt (certificado no válido para navegadores)"
  default     = false
}

# --- Backup automático de la instancia ---

# Snapshot periódico del DISCO RAÍZ de la instancia, gestionado por OVH. Como
# el ejemplo no tiene volumen adicional, cubre todo: sistema y páginas web.
# Los snapshots se facturan por GB almacenado.
#
# OJO: añadir o quitar el bloque auto_backup FUERZA LA RECREACIÓN de la
# instancia, así que por defecto está desactivado para no tocar una máquina
# ya creada. Actívalo al crear la instancia, o asume la recreación.
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

# --- DNS ---

variable "domain" {
  type        = string
  description = "Dominio (zona DNS) ya existente en la cuenta de OVH donde se crea el registro; Terraform no lo compra ni lo registra"
  default     = "virtlabs.es"
}

# Para otra máquina (node02...) basta cambiar este valor.
variable "hostname" {
  type        = string
  description = "Nombre de la máquina dentro de la zona: node01 -> node01.virtlabs.es"
  default     = "node01"
}
