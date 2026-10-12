# Ejemplo de uso de Terraform 02_domain_dns_alias

En este ejemplo gestionamos un registro DNS de un dominio **que ya está
dado de alta en tu cuenta de OVH** (comprado o transferido previamente,
ver [README general de ovh](../README.md)). Terraform no puede registrar
ni comprar el dominio, solo configurar su zona DNS una vez existe.

Se crea un registro tipo `A` para un nombre de máquina (p. ej.
`valinor.virtlabs.es`) apuntando a `server_ip`.

## Sobre los alias de `www` y de la raíz (intento descartado)

Este ejemplo originalmente intentaba además crear un `CNAME` de `www` y
de la raíz del dominio apuntando a `valinor`, para que ambos "siguieran"
automáticamente la IP de `valinor`. Se descartó porque:

- **La raíz no puede ser un `CNAME`**: la zona ya lleva registros
  `SOA`/`NS` obligatorios en la raíz, que no pueden coexistir con un
  `CNAME` (estándar DNS). OVH lo rechaza explícitamente con
  `Invalid subdomain: Subdomain is mandatory for CNAME`.
- **`www` ya tenía un registro `A`** puesto por defecto por OVH al dar de
  alta el dominio, y un `CNAME` no puede coexistir con otro registro en
  el mismo nombre (`CNAME and other data`).
- La alternativa (convertir `www`/raíz a registros `A` con la misma IP
  que `valinor`) sí es técnicamente posible, pero se decidió **no
  tocarlos**: se dejan tal cual estaban antes de este ejemplo, y
  `valinor` se mantiene en su propia IP, sin relación de alias entre
  ambos.

Si en el futuro quieres sí enlazarlos, el camino sería `terraform import`
de los registros existentes de `www` y de la raíz seguido de cambiar su
`fieldtype` a `A` con `target = var.server_ip` (ver `registros.csv` en
esta carpeta para los IDs reales de esos registros en `virtlabs.es`).

# Dónde conseguir las credenciales

| Variable                 | Dónde se consigue |
|--------------------------|-------------------|
| `ovh_endpoint`           | Según tu cuenta: `ovh-eu` (Europa), `ovh-us` o `ovh-ca` |
| `ovh_application_key`    | Se genera al crear el token en https://eu.api.ovh.com/createToken/ |
| `ovh_application_secret` | Ídem (solo se muestra una vez) |
| `ovh_consumer_key`       | Ídem (solo se muestra una vez) |

El paso a paso completo (endpoints de US/Canadá, validez del token,
revocación) está en el
[README general de ovh](../README.md#crear-las-credenciales-de-la-api-desde-la-consola-web-de-ovh).
Este ejemplo **no** usa el id del proyecto Public Cloud: trabaja sobre la
zona DNS del dominio.

# Permisos necesarios en el token de la API

El token necesita derechos sobre la zona del dominio, **distintos** de los
de Public Cloud (un token creado solo con `/cloud/project/*` no sirve
aquí). Al crear el token en
https://eu.api.ovh.com/createToken/ añade:
- `GET /domain/zone/*`
- `POST /domain/zone/*`
- `PUT /domain/zone/*`
- `DELETE /domain/zone/*`

Si prefieres un token más restrictivo, acótalo a tu dominio concreto en
vez de `*`, p. ej. `GET /domain/zone/virtlabs.es/*`.

# Copia el fichero terraform.tfvars.example
<code>cp terraform.tfvars.example terraform.tfvars</code>

Edita el fichero `terraform.tfvars` y pon tus propios valores: endpoint,
credenciales de la API, el dominio, el nombre de máquina (`hostname`) y
la IP del servidor al que debe apuntar.

# Inicialización del despliegue
<code>$ terraform init</code>
# Planificación del despliegue
<code>$ terraform plan</code>
# Despliegue de la infraestructura
<code>$ terraform apply</code>
# Destrucción de la infraestructura
<code>$ terraform destroy</code>

# Nota sobre la propagación de la zona

OVH requiere un **refresh de la zona** para que los cambios de registros
se apliquen de verdad (no solo queden "pendientes"). El provider ya hace
este refresh automáticamente tras aplicar los cambios.

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
