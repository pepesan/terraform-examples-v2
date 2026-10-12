#!/bin/bash
# Idempotente: espera al disco adicional, lo formatea solo si está en blanco
# y lo monta en el directorio indicado como primer argumento.
#
# Uso: montar-datos.sh <punto-de-montaje>      (p. ej. /var/www/html)
# Log: /var/log/montar-datos.log
#
# Lo instala cloud-init (ver cloud-init.yaml.tftpl). Es bash puro, sin
# sintaxis de Terraform: se puede probar a mano y pasarle shellcheck.

MOUNT_POINT="${1:?Uso: $0 <punto-de-montaje>}"

exec >>/var/log/montar-datos.log 2>&1
echo "=== $(date -Is) inicio (montaje en $MOUNT_POINT)"

# Disco del sistema (p. ej. sda) para excluirlo de la búsqueda
ROOT_DISK=$(lsblk -no PKNAME "$(findmnt -no SOURCE /)" | head -1)

# Espera hasta 10 minutos a que aparezca otro disco: el volumen se conecta
# después de crear la instancia, así que puede no estar en el arranque.
DEV=""
for _ in $(seq 1 120); do
  DEV=$(lsblk -dpno NAME,TYPE | awk -v r="/dev/$ROOT_DISK" '$2=="disk" && $1!=r {print $1; exit}')
  [ -n "$DEV" ] && break
  sleep 5
done
if [ -z "$DEV" ]; then
  echo "ERROR: no apareció ningún disco adicional"
  exit 1
fi
echo "disco adicional: $DEV"

# Formatea SOLO si no tiene sistema de ficheros ni particiones
FSTYPE=$(blkid -o value -s TYPE "$DEV")
PARTS=$(lsblk -no TYPE "$DEV" | grep -c part)
if [ -z "$FSTYPE" ] && [ "$PARTS" -eq 0 ]; then
  echo "disco en blanco: formateando como ext4"
  mkfs.ext4 -L datos "$DEV"
  # Conserva lo que ya hubiera en el directorio (p. ej. la página por
  # defecto de nginx), porque al montar encima quedaría oculto
  if [ -d "$MOUNT_POINT" ]; then
    mkdir -p /mnt/nuevo
    mount "$DEV" /mnt/nuevo
    cp -a "$MOUNT_POINT"/. /mnt/nuevo/
    umount /mnt/nuevo
  fi
else
  echo "el disco ya tiene datos (tipo=$FSTYPE, particiones=$PARTS): no se formatea"
fi

# Monta por UUID (más estable que /dev/sdb) y lo deja en fstab
UUID=$(blkid -o value -s UUID "$DEV")
mkdir -p "$MOUNT_POINT"
grep -q "UUID=$UUID" /etc/fstab || echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
systemctl daemon-reload
mount -a
systemctl restart nginx
echo "=== $(date -Is) fin"
