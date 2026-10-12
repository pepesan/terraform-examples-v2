# Ejemplo 02: registro DNS de tipo A en una zona de un dominio que ya está
# dado de alta en la cuenta de OVH (Terraform no lo compra ni lo registra).

# --- Variables (sus valores van en terraform.tfvars, que no se versiona) ---

# Endpoint de la API según la cuenta: "ovh-eu", "ovh-us", "ovh-ca"...
# Si se omite (null), el provider usa la variable de entorno OVH_ENDPOINT.
variable "ovh_endpoint" {
  type    = string
  default = null
}

# Las tres credenciales se generan juntas al crear el token en createToken.
# Este ejemplo necesita permisos sobre /domain/zone/* (no /cloud/project/*).
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

# Dominio (zona DNS) ya existente en la cuenta, p. ej. "virtlabs.es"
variable "domain" {}

# Nombre de la máquina dentro de la zona, p. ej. "valinor" -> valinor.virtlabs.es
variable "hostname" {}

# IPv4 a la que debe apuntar el registro
variable "server_ip" {}

# --- Provider ---

# Autenticación contra la API de OVH con el token (no con usuario/contraseña)
provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

# --- Recursos ---

# Registro A del nombre de máquina (p. ej. valinor.example.com).
# El provider hace el refresh de la zona tras aplicar, para que el cambio
# se publique de verdad y no quede pendiente.
resource "ovh_domain_zone_record" "host" {
  zone      = var.domain
  subdomain = var.hostname
  fieldtype = "A"
  ttl       = 3600 # segundos que los resolvers pueden cachear el registro
  target    = var.server_ip
}

# --- Outputs ---

# Id numérico del registro en OVH (útil para terraform import o para la API)
output "host_record_id" {
  value = ovh_domain_zone_record.host.id
}
