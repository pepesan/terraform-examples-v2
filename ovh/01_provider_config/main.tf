# Ejemplo 01: configuración del provider de OVH y comprobación de que las
# credenciales funcionan listando las regiones del proyecto Public Cloud.

# --- Variables (sus valores van en terraform.tfvars, que no se versiona) ---

# Endpoint de la API según la cuenta: "ovh-eu", "ovh-us", "ovh-ca"...
# Si se omite (null), el provider usa la variable de entorno OVH_ENDPOINT.
variable "ovh_endpoint" {
  type    = string
  default = null
}

# Las tres credenciales se generan juntas al crear el token en createToken
# (ver README general de ovh/).
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

# --- Provider ---

# Autenticación contra la API de OVH con el token (no con usuario/contraseña)
provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

# --- Comprobación de credenciales ---

# Comprobación de credenciales: lista las regiones disponibles
# del proyecto Public Cloud indicado. Si el token no tiene permisos sobre
# /cloud/project/*, aquí falla con 403 "This call has not been granted".
data "ovh_cloud_project_regions" "regions" {
  service_name = var.ovh_public_cloud_project_id
}

# Nombres de las regiones (p. ej. GRA11, SBG5...), para elegir la del ejemplo 03
output "available_regions" {
  value = data.ovh_cloud_project_regions.regions.names
}
