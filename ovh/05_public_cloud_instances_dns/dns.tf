# DNS: un registro A <nodo>.<domain> -> IP pública de cada instancia.
# La zona (dominio) debe existir ya en la cuenta de OVH. El token necesita
# permisos sobre /domain/zone/*.

# for_each sobre los mismos nombres que las instancias: cada registro se crea
# después de la IP de su instancia y se actualiza solo si esa IP cambia (p.
# ej. al recrearla). El provider hace el refresh de la zona tras aplicar.
resource "ovh_domain_zone_record" "node" {
  for_each = local.public_ips

  zone      = var.domain
  subdomain = each.key
  fieldtype = "A"
  ttl       = 3600 # segundos que los resolvers pueden cachear el registro
  target    = each.value
}
