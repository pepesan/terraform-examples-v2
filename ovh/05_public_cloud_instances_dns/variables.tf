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
# El token necesita GET/POST/PUT/DELETE sobre /cloud/project/* (instancias) y
# sobre /domain/zone/* (registros DNS).
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

# --- Nodos ---

# Cada nombre de la lista crea UNA máquina y UN registro DNS
# <nombre>.<domain>. Se indexan por nombre (for_each), no por posición: quitar
# o añadir un nombre solo crea o destruye esa máquina, no toca las demás.
# El nombre sirve a la vez de nombre de instancia y de subdominio DNS.
variable "nodes" {
  type        = list(string)
  description = "Nombres de los nodos (p. ej. [\"nodo01\", \"nodo02\"]); uno por máquina y por registro DNS"
  default     = ["nodo01"]

  validation {
    condition     = length(var.nodes) > 0
    error_message = "nodes no puede estar vacía: al menos un nodo."
  }

  validation {
    condition     = length(var.nodes) == length(distinct(var.nodes))
    error_message = "nodes no puede tener nombres repetidos."
  }

  validation {
    condition     = alltrue([for n in var.nodes : can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", n))])
    error_message = "Cada nodo debe ser un nombre DNS válido: minúsculas, números y guiones, sin empezar ni acabar en guion (máx. 63 caracteres)."
  }
}

variable "domain" {
  type        = string
  description = "Dominio (zona DNS) ya existente en la cuenta de OVH donde se crean los registros; Terraform no lo compra ni lo registra"
  default     = "virtlabs.es"
}

# --- Instancias (iguales para todos los nodos) ---

variable "region" {
  type        = string
  description = "Región donde se crean las instancias (p. ej. GRA11); el catálogo de flavors e imágenes depende de ella"
}

# Una sola clave SSH compartida por todos los nodos. Su nombre no debe
# coincidir con el de otra clave ya existente en el proyecto.
variable "ssh_key_name" {
  type        = string
  description = "Nombre de la clave SSH que se crea en el proyecto y comparten todos los nodos"
  default     = "nodos-key"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Clave pública local que se inyecta en las instancias al crearlas"
  default     = "~/.ssh/id_ed25519.pub"
}

# c3-16: 8 vCPU, 16 GB de RAM y 200 GB de disco raíz. OJO: cada nodo es una
# máquina de ese tamaño y el proyecto tiene cuotas de instancias y de vCPU.
variable "flavor_name" {
  type        = string
  description = "Nombre exacto del flavor de cada nodo"
  default     = "c3-16"
}

variable "image_name" {
  type        = string
  description = "Nombre exacto de la imagen a usar"
  default     = "Ubuntu 26.04"
}

# --- Backup automático de las instancias ---

# Snapshot periódico del disco raíz de cada instancia, gestionado por OVH. Los
# snapshots se facturan por GB almacenado y por NODO.
#
# OJO: añadir o quitar el bloque auto_backup FUERZA LA RECREACIÓN de la
# instancia, así que por defecto está desactivado. Actívalo al crear los
# nodos, o asume la recreación.
variable "backup_enabled" {
  type        = bool
  description = "Activa el backup automático de cada instancia (auto_backup); cambiarlo recrea las instancias"
  default     = false
}

# Formato cron de 5 campos: minuto hora día-del-mes mes día-de-la-semana.
variable "backup_cron" {
  type        = string
  description = "Cuándo se hace el backup automático, en formato cron Unix"
  default     = "0 3 * * *"
}

variable "backup_rotation" {
  type        = number
  description = "Cuántos backups automáticos se conservan por instancia"
  default     = 7

  validation {
    condition     = var.backup_rotation >= 1
    error_message = "backup_rotation debe ser al menos 1."
  }
}
