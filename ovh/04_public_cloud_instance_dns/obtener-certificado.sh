#!/bin/bash
# Pide un certificado TLS de Let's Encrypt con certbot y configura nginx.
#
# Uso: obtener-certificado.sh <fqdn> <email> [staging]
#   fqdn     nombre DNS de la máquina (p. ej. node01.virtlabs.es)
#   email    correo para avisos de caducidad de Let's Encrypt
#   staging  "true" usa el entorno de pruebas (certificado no válido para
#            navegadores, pero sin los límites de uso del real)
#
# Log: /var/log/certbot-inicial.log. Lo instala cloud-init y corre en
# segundo plano (ver cloud-init.yaml.tftpl). La renovación posterior la
# hace el temporizador systemd que instala el paquete certbot.

FQDN="${1:?Uso: $0 <fqdn> <email> [staging]}"
EMAIL="${2:?Uso: $0 <fqdn> <email> [staging]}"
STAGING="${3:-false}"

exec >>/var/log/certbot-inicial.log 2>&1
echo "=== $(date -Is) inicio ($FQDN, staging=$STAGING)"

# Espera a que cloud-init termine de instalar nginx y certbot (hasta 10 min)
for _ in $(seq 1 120); do
  command -v certbot >/dev/null && [ -f /etc/nginx/sites-enabled/default ] && break
  sleep 5
done
if ! command -v certbot >/dev/null; then
  echo "ERROR: certbot no está instalado"
  exit 1
fi

# IPv4 pública de esta máquina (está en la propia interfaz)
MY_IP=$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -1)
echo "IP propia: $MY_IP"

# Espera a que el nombre DNS resuelva a esta IP (hasta 30 min). El registro
# se crea en el mismo apply, justo después de la instancia, y tarda en
# propagarse; pedir el certificado antes fallaría y consume el límite de
# intentos fallidos de Let's Encrypt.
RESOLVED=""
for _ in $(seq 1 120); do
  RESOLVED=$(getent ahostsv4 "$FQDN" | awk '{print $1; exit}')
  [ "$RESOLVED" = "$MY_IP" ] && break
  sleep 15
done
if [ "$RESOLVED" != "$MY_IP" ]; then
  echo "ERROR: $FQDN resuelve a '${RESOLVED:-nada}', no a $MY_IP; no se pide el certificado"
  exit 1
fi
echo "$FQDN resuelve a $MY_IP"

# El sitio por defecto de nginx usa "server_name _;": certbot necesita que
# el bloque tenga el nombre del dominio para poder editarlo
sed -i "s/server_name _;/server_name $FQDN;/" /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

ARGS=(--nginx -d "$FQDN" -m "$EMAIL" --agree-tos --no-eff-email --non-interactive --redirect)
[ "$STAGING" = "true" ] && ARGS+=(--staging)
certbot "${ARGS[@]}"
echo "=== $(date -Is) fin (certbot salió con $?)"
