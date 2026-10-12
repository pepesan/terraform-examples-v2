# Ejemplo de uso de Terraform 05_public_cloud_instances_dns

Es el [04_public_cloud_instance_dns](../04_public_cloud_instance_dns/README.md)
con un **número variable de máquinas**: le pasas una lista de nombres
(`nodes`) y crea, por cada nombre, una instancia de OVH Public Cloud con
nginx y un registro DNS `A` `<nombre>.<domain>` que apunta a su IP pública.

```hcl
nodes  = ["nodo01", "nodo02", "nodo03"]
domain = "virtlabs.es"
```

crea `nodo01.virtlabs.es`, `nodo02.virtlabs.es` y `nodo03.virtlabs.es`.

## Qué cambia respecto al 04

| | 04 | 05 |
|---|---|---|
| Máquinas | 1 (`instance_name`) | N (una por nombre de `nodes`) |
| Nombre DNS | `hostname` + `domain` | `<nodo>.<domain>`, el mismo nombre que la instancia |
| Clave SSH | una por instancia | **una compartida** (`ssh_key_name`) |
| Recursos | `resource` simples | `for_each` sobre los nombres |
| Outputs | sueltos | un objeto `nodes` por nodo y la lista `fqdns` |

## La lista `nodes`

- **Una máquina y un registro DNS por nombre.** El nombre es a la vez el
  nombre de la instancia y el subdominio.
- **`for_each` indexa por nombre, no por posición.** Añadir `nodo04` solo
  crea esa máquina y su registro; quitar `nodo02` solo destruye `nodo02`.
  Con `count` (por posición) quitar uno del medio desplazaría los demás y
  recrearía máquinas que no querías tocar.
- **Validaciones:** al menos un nodo, sin nombres repetidos y cada nombre
  un DNS válido (minúsculas, números y guiones, sin empezar ni acabar en
  guion, máx. 63 caracteres).
- **Cambiar un nombre** equivale a destruir el nodo antiguo y crear uno
  nuevo (el nombre de una instancia no es modificable in situ).

## Estructura del código

| Fichero | Contenido |
|---|---|
| `versions.tf` | Versión de Terraform y del provider `ovh/ovh` |
| `provider.tf` | Configuración del provider (endpoint y credenciales) |
| `variables.tf` | Variables de entrada, con `type`, `description` y validaciones |
| `main.tf` | Catálogo de flavors/imágenes, la clave SSH compartida y las instancias (`for_each`) |
| `dns.tf` | Un registro `A` por nodo |
| `outputs.tf` | `nodes` (objeto por nodo), `fqdns`, `flavor_id_used`, `image_id_used` |
| `cloud-init.yaml.tftpl` | `user_data`: instala nginx y publica un `index.html` que identifica el nodo |

## Variables

| Variable | Por defecto | Significado |
|---|---|---|
| `nodes` | `["nodo01"]` | Nombres de los nodos |
| `domain` | `virtlabs.es` | Zona DNS existente en tu cuenta de OVH |
| `region` | — | Región de las instancias |
| `ssh_key_name` | `nodos-key` | Clave SSH compartida (no debe existir ya en el proyecto) |
| `flavor_name` | `c3-16` | Flavor de cada nodo (8 vCPU, 16 GB, 200 GB de disco) |
| `backup_enabled` / `backup_cron` / `backup_rotation` | `false` / `0 3 * * *` / `7` | `auto_backup` de cada instancia; activarlo o quitarlo recrea las instancias |

## Coste y cuotas

Cada nodo es una `c3-16`: en el catálogo público de OVH (ES, sin IVA) son
unos **0,1825 €/h**, así que `n` nodos cuestan `n × 0,1825 €/h` (3 nodos ≈
0,55 €/h ≈ 16,4 € por 30 horas). Precios orientativos; pueden cambiar.
Además, el proyecto tiene **cuotas de instancias y de vCPU** (cada `c3-16`
son 8 vCPU): con muchos nodos la creación puede fallar por cuota aunque el
`plan` pase. Se facturan por tiempo de existencia: hay que hacer `destroy`
al terminar.

## Permisos del token

`GET/POST/PUT/DELETE` sobre `/cloud/project/*` y sobre `/domain/zone/*`
(o acotado a `/domain/zone/<tu-dominio>/*`). Ver
[permisos en el README general](../README.md#2-permisos-rights-a-marcar-según-lo-que-vayas-a-gestionar).

## Uso

<code>$ cp terraform.tfvars.example terraform.tfvars</code>
<code>$ terraform init</code>
<code>$ terraform plan</code>
<code>$ terraform apply</code>
<code>$ terraform destroy</code>

Consultar los nodos (tras el `apply`):

<code>$ terraform output nodes</code>
<code>$ terraform output -json nodes | jq -r '.nodo01.ssh_connection'</code>
<code>$ terraform output -json nodes | jq -r 'to_entries[] | "\(.key) \(.value.public_ip)"'</code>

nginx y los registros DNS tardan 1-2 minutos en responder. El
`index.html` de cada nodo muestra su nombre, el flavor y la fecha de
despliegue.

## Avisos

- **El dominio debe estar activo y delegado** para que los nombres
  resuelvan desde Internet. Si está «En creación» en el Manager, Terraform
  crea los registros igualmente, pero no se verán hasta que termine.
- **Una sola clave SSH para todos los nodos:** quien tenga la clave privada
  entra en todos.
- **`user_data` solo se ejecuta al crear la instancia:** cambiar
  `cloud-init.yaml.tftpl` recrea todos los nodos.
- **Sin certbot (de momento):** solo HTTP. El 04 tiene la lógica de TLS
  apagada por defecto si se quiere trasladar más adelante.

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
