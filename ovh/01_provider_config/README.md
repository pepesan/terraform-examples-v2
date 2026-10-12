# Ejemplo de uso de Terraform 01_provider_config

En este ejemplo configuramos el provider de OVH para Terraform, enfocado a
**Public Cloud** (no a los productos de infraestructura dedicada como VPS,
Dedicated Server o dominios, que usan otras APIs/credenciales).

Como comprobación de que las credenciales funcionan, el ejemplo lista las
regiones de Public Cloud disponibles para el proyecto indicado.

# Dónde conseguir las credenciales

Este ejemplo necesita cinco valores en `terraform.tfvars`:

| Variable                      | Dónde se consigue |
|-------------------------------|-------------------|
| `ovh_endpoint`                | Según tu cuenta: `ovh-eu` (Europa), `ovh-us` o `ovh-ca` |
| `ovh_application_key`         | Se genera al crear el token en https://eu.api.ovh.com/createToken/ |
| `ovh_application_secret`      | Ídem (solo se muestra una vez) |
| `ovh_consumer_key`            | Ídem (solo se muestra una vez) |
| `ovh_public_cloud_project_id` | Manager de OVH > Public Cloud > selector de proyecto (icono de copiar el id), o `GET /cloud/project` |

**Permisos que hay que marcar al crear el token** (en `createToken`, una
fila por método): `GET`, `POST`, `PUT` y `DELETE` sobre `/cloud/project/*`.
Para solo ejecutar este ejemplo bastaría con `GET`, pero el token se
reutiliza en el [03](../03_public_cloud_instance_volume_cloud_init/README.md), que sí crea y
borra recursos.

El paso a paso completo (endpoints de US/Canadá, validez del token,
revocación) está en el
[README general de ovh](../README.md#crear-las-credenciales-de-la-api-desde-la-consola-web-de-ovh).

# Copia el fichero terraform.tfvars.example
<code>cp terraform.tfvars.example terraform.tfvars</code>

Edita el fichero `terraform.tfvars` y pon tus propios valores: endpoint,
application key, application secret, consumer key y el id del proyecto
Public Cloud.

# Inicialización del despliegue
<code>$ terraform init</code>
# Planificación del despliegue
<code>$ terraform plan</code>
# Despliegue de la infraestructura
<code>$ terraform apply</code>
# Destrucción de la infraestructura
<code>$ terraform destroy</code>

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
