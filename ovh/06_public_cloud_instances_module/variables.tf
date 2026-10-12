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
# OVH_CONSUMER_KEY). El token necesita GET/POST/PUT/DELETE sobre
# /cloud/project/* y /domain/zone/*.
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

# Cada nombre crea una llamada al módulo node: una máquina y un registro DNS.
variable "nodes" {
  type        = list(string)
  description = "Nombres de los nodos (p. ej. [\"nodo01\", \"nodo02\"])"
  default     = ["nodo01"]

  validation {
    condition     = length(var.nodes) > 0
    error_message = "nodes no puede estar vacía: al menos un nodo."
  }

  validation {
    condition     = length(var.nodes) == length(distinct(var.nodes))
    error_message = "nodes no puede tener nombres repetidos."
  }
}

variable "domain" {
  type        = string
  description = "Dominio ya existente en la cuenta de OVH donde se crean los registros"
  default     = "virtlabs.es"
}

# --- Instancias (iguales para todos los nodos) ---

variable "region" {
  type        = string
  description = "Región donde se crean las instancias (p. ej. GRA11)"
}

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

variable "flavor_name" {
  type        = string
  description = "Nombre exacto del flavor de cada nodo"
  default     = "c3-16"
}

# Flavor distinto para algunos nodos; los que no aparecen usan flavor_name.
# Ej.: node_flavors = { nodo03 = "c3-8" }. Cambiar el flavor de un nodo ya
# creado RECREA esa instancia (y su IP cambia).
variable "node_flavors" {
  type        = map(string)
  description = "Flavor por nodo (nombre del nodo -> flavor); los nodos ausentes usan flavor_name"
  default     = {}

  validation {
    condition     = alltrue([for n in keys(var.node_flavors) : contains(var.nodes, n)])
    error_message = "node_flavors solo puede llevar nombres que estén en nodes."
  }
}

variable "image_name" {
  type        = string
  description = "Nombre exacto de la imagen a usar"
  default     = "Ubuntu 26.04"
}

# Cambiar backup_enabled sobre instancias creadas las RECREA.
variable "backup_enabled" {
  type        = bool
  description = "Activa el backup automático de cada instancia; cambiarlo recrea las instancias"
  default     = false
}

variable "backup_cron" {
  type        = string
  description = "Cuándo se hace el backup automático, en formato cron Unix"
  default     = "0 3 * * *"
}

variable "backup_rotation" {
  type        = number
  description = "Cuántos backups automáticos se conservan por instancia"
  default     = 7
}

# --- Inventario CSV ---

# Fichero CSV (ip,fqdn) con una fila por nodo. Contiene IPs reales: por eso
# *.csv está en el .gitignore y no debe versionarse.
variable "inventory_csv_path" {
  type        = string
  description = "Ruta del fichero CSV que relaciona IP y fqdn de cada nodo; relativa a este directorio"
  default     = "nodos.csv"
}
