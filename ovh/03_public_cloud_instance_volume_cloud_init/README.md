# Ejemplo de uso de Terraform 03_public_cloud_instance

En este ejemplo creamos una instancia (VM) en **OVH Public Cloud**:
Ubuntu 26.04, ~4 vCPU / 8 GB RAM, con un disco adicional de 200 GB, una
clave SSH local inyectada al crearla, e IP pública. Con cloud-init instala
**nginx** y monta el disco adicional en `/var/www/html`, el directorio
donde nginx sirve las páginas web por defecto.

## Cómo se elige el tamaño (flavor) y la imagen

OVH identifica el tamaño de máquina con un **flavor de nombre fijo** (p.
ej. `c3-8`), no con vCPU/RAM libres, y el catálogo de flavors/imágenes
varía según la región. Este ejemplo usa dos variables con un **valor
concreto y explícito**:
- `flavor_name` (por defecto `c3-8`): 4 vCPU / 8 GB RAM / 100 GB de disco
  raíz incluido. Confirmado disponible (`available = true`) en la región
  `GRA11` en el momento de escribir este ejemplo.
- `image_name` (por defecto `Ubuntu 26.04`): la imagen estable, sin sufijo
  `UEFI`/`NVIDIA`.

El `main.tf` sigue usando los data sources `ovh_cloud_project_flavors`
(con `name_filter = var.flavor_name`) y `ovh_cloud_project_images` solo
para traducir esos nombres a los `id` internos que pide la API — no para
"adivinar" el tamaño, sino para resolver el nombre exacto que tú ya
decidiste.

### Cómo consultar tú mismo el catálogo de tu región

Los nombres y la disponibilidad cambian por región y con el tiempo. Para
comprobarlo contra tu propia cuenta sin modificar nada, puedes crear un
directorio temporal con este `main.tf` mínimo (usando las mismas
credenciales de tu `terraform.tfvars`) y mirar el resultado del `plan`
sin llegar a aplicarlo:

```hcl
variable "ovh_endpoint" {}
variable "ovh_application_key" {}
variable "ovh_application_secret" {}
variable "ovh_consumer_key" {}
variable "ovh_public_cloud_project_id" {}
variable "region" { default = "GRA11" }

provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

data "ovh_cloud_project_flavors" "all" {
  service_name = var.ovh_public_cloud_project_id
  region       = var.region
}

output "flavors" {
  value = [for f in data.ovh_cloud_project_flavors.all.flavors : "${f.name}: ${f.vcpus} vCPU, ${f.ram}GB RAM, ${f.disk}GB disco, disponible=${f.available}"]
}
```

`terraform init` + `terraform plan -var-file=../terraform.tfvars` (o
`terraform apply` si quieres verlo como output persistente) te mostrará
todos los flavors de tu región con sus vCPU/RAM/disco reales. Haz lo
mismo con `ovh_cloud_project_images` (`os_type = "linux"`) para ver los
nombres de imagen disponibles. Ajusta `flavor_name`/`image_name` en tu
`terraform.tfvars` si el valor por defecto no está disponible en tu
región o cuenta.

## Sobre la IP pública

`network { public = true }` le da a la instancia una IP pública fija
mientras la instancia exista (no cambia con reinicios ni paradas). Si en
algún momento destruyes y vuelves a crear la instancia, la IP sí puede
cambiar. Para que sobreviva incluso a eso haría falta montar una red
privada + gateway + floating IP real, bastante más complejo — fuera de
alcance de este ejemplo pensado para una prueba simple.

## Sobre el disco de 200 GB

El flavor trae un disco raíz pequeño y fijo (no configurable). Los 200 GB
se añaden como un volumen adicional (`ovh_cloud_project_volume`) asociado
a la instancia — aparecerá como un segundo disco dentro de la VM, no
sustituye al disco raíz del sistema. OVH solo lo conecta en bruto (sin
formato ni montaje); de eso se encarga el `user_data` de cloud-init, ver
[nginx y montaje automático del disco](#nginx-y-montaje-automático-del-disco-cloud-init).

## Backup automático de la instancia

El bloque `auto_backup` de `ovh_cloud_project_instance` programa un
snapshot periódico del **disco raíz**, y OVH conserva los últimos
`rotation`. Se controla con tres variables:

| Variable | Por defecto | Significado |
|---|---|---|
| `backup_enabled` | `false` | Activa el backup automático |
| `backup_cron` | `0 3 * * *` | Cuándo, en formato cron Unix (todos los días a las 03:00) |
| `backup_rotation` | `7` | Cuántos backups se conservan (mínimo 1) |

Avisos importantes:

- **Activarlo o desactivarlo recrea la instancia** (el `plan` marca
  `auto_backup # forces replacement`) y, con ella, el volumen, que pierde
  sus datos. Por eso viene desactivado. Actívalo al crear una instancia
  nueva.
- **No cubre el volumen de 200 GB**, donde están las páginas web: ese
  recurso es aparte y su backup no se programa con este bloque.
- Los snapshots **se facturan por GB** almacenado.

## Dónde conseguir las credenciales

| Variable                      | Dónde se consigue |
|-------------------------------|-------------------|
| `ovh_endpoint`                | Según tu cuenta: `ovh-eu` (Europa), `ovh-us` o `ovh-ca` |
| `ovh_application_key`         | Se genera al crear el token en https://eu.api.ovh.com/createToken/ |
| `ovh_application_secret`      | Ídem (solo se muestra una vez) |
| `ovh_consumer_key`            | Ídem (solo se muestra una vez) |
| `ovh_public_cloud_project_id` | Manager de OVH > Public Cloud > selector de proyecto (icono de copiar el id), o `GET /cloud/project` |

El paso a paso completo (endpoints de US/Canadá, validez del token,
revocación) está en el
[README general de ovh](../README.md#crear-las-credenciales-de-la-api-desde-la-consola-web-de-ovh).
Puedes reutilizar el token del [01_provider_config](../01_provider_config/README.md)
siempre que se creara con los permisos de abajo.

## Permisos necesarios en el token de la API

Al crear el token, añade los 4 métodos (`GET`, `POST`, `PUT`, `DELETE`)
sobre `/cloud/project/*`. Este ejemplo **crea y borra** instancias,
volúmenes y claves SSH, así que con solo `GET` no basta.

Si `terraform plan` falla con `403 Client::Forbidden: "This call has not
been granted"`, el token no tiene esa regla: crea uno nuevo con los
permisos de arriba y cambia las tres credenciales (`application_key`,
`application_secret` y `consumer_key`) a la vez.

# Copia el fichero terraform.tfvars.example
<code>cp terraform.tfvars.example terraform.tfvars</code>

Edita el fichero `terraform.tfvars` y pon tus propios valores: endpoint,
credenciales de la API, el id del proyecto Public Cloud, la región, el
nombre de la instancia y la ruta a tu clave pública SSH.

# Inicialización del despliegue
<code>$ terraform init</code>
# Planificación del despliegue
<code>$ terraform plan</code>
# Despliegue de la infraestructura
<code>$ terraform apply</code>
# Destrucción de la infraestructura
<code>$ terraform destroy</code>

**Importante**: a diferencia de los ejemplos de DNS, esto crea una
instancia y un volumen reales con coste económico (facturación por hora
con `billing_period = "hourly"`). No olvides el `terraform destroy` al
terminar las pruebas.

# Conectarse por SSH

Una vez aplicado, el output `ssh_connection` devuelve el comando completo
(usa la clave privada que corresponde a `ssh_public_key_path`, es decir,
la misma ruta sin el `.pub`, y el usuario `ubuntu` de la imagen):

<code>$ terraform output -raw ssh_connection</code>

Para ejecutarlo directamente:

<code>$ $(terraform output -raw ssh_connection)</code>

El resultado tiene esta forma (con la IP de tu instancia):

```
ssh -i ~/.ssh/id_ed25519 ubuntu@<ip-publica>
```

Si prefieres la IP sola, sigue disponible el output `public_ip`:
<code>$ terraform output -raw public_ip</code>

La primera conexión pide aceptar la huella del servidor
(`yes`), y puede tardar 1-2 minutos tras el `apply` en responder.

## Comprobar los discos dentro de la VM

<code>$ lsblk -o NAME,SIZE,TYPE,MOUNTPOINT</code>
<code>$ df -h /var/www/html</code>

El volumen de 200 GB aparece como un segundo disco (típicamente `sdb`)
montado en `/var/www/html` (ver la sección siguiente). Si no está montado,
mira el log del script: `sudo cat /var/log/montar-datos.log`.

## nginx y montaje automático del disco (cloud-init)

La instancia se crea con `user_data`, formado por dos ficheros:

- `cloud-init.yaml.tftpl`: la configuración de cloud-init (paquetes,
  `write_files`, `runcmd`), renderizada con `templatefile`.
- `montar-datos.sh`: el script de montaje, en bash puro y sin sintaxis de
  Terraform. Se incrusta en la plantilla con `indent()`, y el punto de
  montaje le llega como argumento. Se puede revisar con `shellcheck` o
  probar a mano: `sudo ./montar-datos.sh /var/www/html`.

En el **primer arranque** hace lo siguiente:

1. Instala **nginx**.
2. Espera a que OVH conecte el disco adicional.
3. Lo formatea como `ext4` **solo si está en blanco** (sin sistema de
   ficheros ni particiones).
4. Copia dentro lo que ya hubiera en `/var/www/html` (la página por
   defecto de nginx) y lo monta ahí, por `UUID` y con `nofail` en
   `/etc/fstab` para que sobreviva a los reinicios.

Así, todo lo que se publique en el directorio web por defecto de nginx
queda en el volumen de 200 GB y no en el disco raíz.

**Por qué un script con espera y no el `fs_setup`/`mounts` nativo de
cloud-init:** el volumen se crea y se conecta *después* de la instancia
(depende de su `instance_id`), así que en el primer arranque el disco puede
no existir aún, y cloud-init no reintenta. El script espera hasta 10
minutos a que aparezca. Corre en segundo plano
(`systemd-run --unit=montar-datos`) para no bloquear el arranque.

El punto de montaje se cambia con la variable `data_mount_point` (por
defecto `/var/www/html`).

### Comprobar el resultado

Tras el `apply` espera 1-2 minutos y prueba:

<code>$ curl -I $(terraform output -raw web_url)</code>
<code>$ $(terraform output -raw ssh_connection) 'df -h /var/www/html; cat /var/log/montar-datos.log'</code>

Debe responder `200 OK` con la página de bienvenida de nginx, y `df` debe
mostrar `/dev/sdb` de ~200 GB montado en `/var/www/html`.

### Avisos

- **`user_data` solo se ejecuta al crear la instancia:** cambiarlo (o
  `data_mount_point`) obliga a **recrearla**, y con ella el volumen, que
  pierde sus datos.
- **No se formatea un disco con datos:** si el disco ya tiene sistema de
  ficheros o particiones, el script solo lo monta.
- **`lost+found`:** `ext4` crea ese directorio en la raíz del volumen, así
  que aparece dentro de `/var/www/html`. nginx no lo lista por defecto.
- **Puerto 80:** hay que tener abierto el acceso desde Internet; si no
  responde, revisa el cortafuegos del proyecto en el panel de OVH.

## Credenciales por variables de entorno (opcional)

En vez de poner `ovh_endpoint`, `ovh_application_key`,
`ovh_application_secret` y `ovh_consumer_key` en `terraform.tfvars`, se
pueden exportar como variables de entorno; así no hay secretos en un
fichero junto al código. Esas cuatro variables de Terraform valen `null`
por defecto y, en ese caso, el provider las lee del entorno:

```bash
export OVH_ENDPOINT=ovh-eu
export OVH_APPLICATION_KEY=...
export OVH_APPLICATION_SECRET=...
export OVH_CONSUMER_KEY=...
terraform plan
```

Si no hay credenciales ni en `tfvars` ni en el entorno, el provider
falla con «missing authentication information».

## Puertos y cortafuegos

Este ejemplo **no declara ninguna regla de cortafuegos**. En las pruebas
con esta cuenta y región, el puerto 22 (SSH) y el 80 (HTTP) respondieron
desde Internet sin configurar nada; el 443 no se ha probado. No se ha
verificado cómo exponer o restringir puertos desde Terraform en OVH (el
provider tiene `ovh_cloud_security_group`, pero el recurso de instancia no
tiene un atributo para asociarlo). Si necesitas restringirlos, hazlo con
`ufw` en `cloud-init` o desde el panel de OVH.

## Cambios que recrean la máquina

Estos cambios **destruyen y recrean** la instancia (y pierden su
contenido y, posiblemente, su IP pública):

- `instance_name` / el nombre del nodo (el nombre no es modificable in situ).
- `flavor_name` e `image_name`.
- El contenido del `user_data` (`cloud-init`), que solo se ejecuta al crear.
- Activar o desactivar `backup_enabled` (bloque `auto_backup`).

Revisa siempre el `plan` y busca `must be replaced` / `forces replacement`
antes de aplicar.

## Validación de flavor e imagen

Si `flavor_name` o `image_name` no existen en la región, el `plan` falla
con un mensaje claro (`precondition`), por ejemplo: «El flavor 'xyz' no
existe en la región GRA11. Consulta el catálogo…». Antes daba un críptico
`Invalid index`.
