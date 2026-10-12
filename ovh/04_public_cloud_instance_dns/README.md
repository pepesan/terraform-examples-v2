# Ejemplo de uso de Terraform 04_public_cloud_instance_dns

Es el [03_public_cloud_instance](../03_public_cloud_instance_volume_cloud_init/README.md) más
un **registro DNS** de tipo `A` (por defecto `node01.virtlabs.es`) que
apunta a la IP pública de la instancia, como en el
[02_domain_dns_alias](../02_domain_dns_alias/README.md). El dominio debe
estar ya dado de alta en tu cuenta de OVH; Terraform no lo compra.

Las variables nuevas respecto al 03 son `domain` (por defecto
`virtlabs.es`) y `hostname` (por defecto `node01`; para otra máquina,
`node02`...). El resto del README es el del 03.

## Qué cambia el 04 respecto al 03

- **Flavor `c3-16` y sin volumen adicional:** 8 vCPU, 16 GB de RAM y
  **200 GB de disco raíz**. Las páginas web de nginx (`/var/www/html`)
  viven en ese disco, así que no hay volumen que formatear ni montar, y
  `auto_backup` cubre todo. Se eliminaron las variables `volume_type` y
  `data_mount_point`, el volumen y el script `montar-datos.sh`.
- **Coste:** unos 0,1825 €/h (≈5,5 € por 30 horas) frente a unos
  0,1151 €/h de `c3-8` + 200 GB `high-speed`, sin IVA. Precios del
  catálogo público de OVH; pueden cambiar.

## Qué añade el 04 al 03

- **Recurso `ovh_domain_zone_record.node`:** registro `A`
  `<hostname>.<domain>` con `target` = IP pública de la instancia. Depende
  de la IP, así que se crea después de la instancia y se actualiza solo si
  la IP cambia (p. ej. al recrearla).
- **Outputs nuevos:** `fqdn` y `dns_record_id`; `web_url` pasa a usar el
  nombre DNS en vez de la IP.
- **Permisos del token:** además de `/cloud/project/*`, hacen falta
  `GET/POST/PUT/DELETE` sobre `/domain/zone/*` (o acotado a
  `/domain/zone/<tu-dominio>/*`). Ver
  [permisos en el README general](../README.md#2-permisos-rights-a-marcar-según-lo-que-vayas-a-gestionar).
- **`instance_name` y `hostname` son independientes:** el nombre de la
  instancia no es modificable in situ (cambiarlo la recrea), mientras que
  el nombre DNS se cambia sin tocar la máquina.

## Estructura del código

El código está dividido por componentes, como un módulo de Terraform:

| Fichero | Contenido |
|---|---|
| `versions.tf` | Versión de Terraform y del provider `ovh/ovh` |
| `provider.tf` | Configuración del provider (endpoint y credenciales) |
| `variables.tf` | Todas las variables de entrada, con `type` y `description`; `ovh_application_secret` y `ovh_consumer_key` van como `sensitive` |
| `main.tf` | La máquina: catálogo de flavors/imágenes, clave SSH e instancia (sin volumen adicional) |
| `dns.tf` | El registro DNS `A` |
| `outputs.tf` | Las salidas: `fqdn`, `dns_record_id`, `instance_id`, `public_ip`, `ssh_connection`, `web_url`... |
| `cloud-init.yaml.tftpl` | `user_data` de la instancia: instala nginx, publica un `index.html` identificativo y, si hay correo, pide el certificado |
| `obtener-certificado.sh` | Script de certbot que cloud-init instala y lanza en segundo plano |

Terraform carga todos los `.tf` del directorio juntos, así que dividirlo no
cambia el resultado: el `plan` es el mismo que con un único `main.tf`.

## Certificado TLS con certbot (opcional)

Con la variable `certbot_email` informada, cloud-init instala `certbot` y
`python3-certbot-nginx` y pide un certificado de Let's Encrypt para
`<hostname>.<domain>`; certbot configura nginx con HTTPS y redirige desde
HTTP. Con `certbot_email = ""` (por defecto) no se instala ni se pide nada.

| Variable | Por defecto | Significado |
|---|---|---|
| `certbot_email` | `""` | Correo para Let's Encrypt; vacío = solo HTTP |
| `certbot_staging` | `false` | `true` usa el entorno de pruebas (cert no válido para navegadores, sin límites de uso) |

Cómo funciona `obtener-certificado.sh` (corre en segundo plano, log en
`/var/log/certbot-inicial.log`):

1. Espera a que nginx y certbot estén instalados.
2. **Espera a que `<fqdn>` resuelva a la IP de la propia máquina** (hasta
   30 min). El registro DNS se crea en el mismo `apply`, justo después de
   la instancia, y tarda en propagarse; pedir el certificado antes
   fallaría y consumiría el límite de intentos fallidos.
3. Cambia `server_name _;` del sitio por defecto por el nombre real
   (certbot lo necesita para encontrar el bloque).
4. Ejecuta `certbot --nginx -d <fqdn> -m <email> --agree-tos --redirect`.

La renovación la hace el temporizador `certbot.timer` que instala el
paquete. El output `web_url` pasa a ser `https://...` si hay correo.

Avisos:

- **El dominio debe estar delegado públicamente:** Let's Encrypt valida por
  HTTP desde Internet. Si `<fqdn>` no resuelve desde fuera, el script agota
  la espera y no pide nada (el log lo indica).
- **Puertos 80 y 443** abiertos desde Internet.
- **Ensaya con `certbot_staging = true`** primero: el entorno real limita
  los intentos fallidos y los certificados duplicados por semana.
- **Cambiarlo recrea la instancia** (cambia el `user_data`).
- **No probado en una VM real:** que `python3-certbot-nginx` esté en los
  repositorios de Ubuntu 26.04 y el flujo completo se confirman en el
  primer `apply`.

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
  `auto_backup # forces replacement`). Por eso viene desactivado por
  defecto. Actívalo al crear una instancia nueva.
- **Cubre todo el disco:** como el ejemplo no tiene volumen adicional,
  el snapshot incluye el sistema y las páginas web (`/var/www/html`).
- Los snapshots **se facturan por GB** almacenado.

## Partir del estado del 03

Este directorio se creó copiando el 03 **con su `terraform.tfstate` y su
`terraform.tfvars`**, de modo que Terraform conoce la instancia, el
volumen y la clave SSH ya creados. Con el código actual (flavor `c3-16`,
sin volumen, `user_data` nuevo) el `plan` **recrea la instancia**, elimina
el volumen antiguo y crea el registro DNS. Si quisieras conservar la
máquina `c3-8` del 03, no cambies `flavor_name`. Dos consecuencias:

- **Desde ese momento el estado vigente es el de este directorio.** No
  ejecutes `apply` ni `destroy` en el 03 con su copia del estado: se
  desincronizaría y podría intentar recrear o duplicar recursos.
- Si empiezas desde cero (sin copiar el estado), el 04 crea todo, igual que
  el 03.

## Comprobar el registro

<code>$ terraform output fqdn</code>
<code>$ dig +short $(terraform output -raw fqdn) @ns.ovh.net</code>
<code>$ curl -I $(terraform output -raw web_url)</code>

La resolución puede tardar unos minutos en propagarse según el TTL (3600 s)
y la caché de tu resolver.

---

# Resto del README (heredado del 03)

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

El flavor `c3-16` trae **200 GB de disco raíz** incluidos en su precio, así
que este ejemplo no crea ningún volumen aparte. El disco raíz del flavor es
de tamaño fijo (no se redimensiona) y se pierde si se recrea la instancia.

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
sobre `/cloud/project/*` **y** sobre `/domain/zone/*`. Este ejemplo
**crea y borra** instancias, volúmenes, claves SSH y registros DNS, así
que con solo `GET` no basta.

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
instancia real con coste económico (facturación por hora
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

## Comprobar el disco y nginx

Tras el `apply`, espera 1-2 minutos (cloud-init instala nginx):

<code>$ curl -I $(terraform output -raw web_url)</code>
<code>$ $(terraform output -raw ssh_connection) 'df -h /; lsblk; systemctl is-active nginx'</code>

Debe responder `200 OK` con la página de bienvenida de nginx, y `df -h /`
debe mostrar un disco raíz de ~200 GB.

## nginx (cloud-init)

La instancia se crea con `user_data` (fichero `cloud-init.yaml.tftpl`,
renderizado con `templatefile`), que en el primer arranque:

1. Instala **nginx**.
2. Publica `/var/www/html/index.html`, una página que muestra el nombre
   DNS, la instancia, el flavor y la fecha de despliegue, para comprobar a
   simple vista que la máquina la hemos desplegado nosotros. Se escribe con
   `defer: true`, después de instalar nginx, y sustituye a la página por
   defecto («Welcome to nginx!»).

Cambiarlo obliga a **recrear** la instancia, porque cloud-init solo se
ejecuta al crearla. Para ver el resultado: `curl $(terraform output -raw web_url)`.

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
