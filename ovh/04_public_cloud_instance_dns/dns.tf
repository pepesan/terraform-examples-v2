# DNS: registro A <hostname>.<domain> -> IP pública de la instancia.
# La zona (dominio) debe existir ya en la cuenta de OVH. El token necesita
# permisos sobre /domain/zone/*.

# Depende de la IP (local.public_ip, definida en main.tf), así que se crea
# después de la instancia y se actualiza solo si la IP cambia (p. ej. al
# recrearla). El provider hace el refresh de la zona tras aplicar, para que
# el cambio se publique de verdad y no quede pendiente.
resource "ovh_domain_zone_record" "node" {
  zone      = var.domain
  subdomain = var.hostname
  fieldtype = "A"
  ttl       = 3600 # segundos que los resolvers pueden cachear el registro
  target    = local.public_ip
}
