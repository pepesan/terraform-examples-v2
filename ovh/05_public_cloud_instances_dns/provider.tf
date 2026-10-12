# Provider de OVH. La versión del provider se fija en versions.tf.

# Autenticación contra la API de OVH con el token (no con usuario/contraseña)
provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}
