# Ejemplos de Terraform para OVH

Esta carpeta contiene ejemplos de uso de Terraform con el
[provider de OVH](https://registry.terraform.io/providers/ovh/ovh/latest),
enfocados principalmente a **Public Cloud** (no a los productos de
infraestructura dedicada como VPS, Dedicated Server o dominios, que usan
otras APIs/credenciales).

## Contenido de la carpeta

Cada subcarpeta numerada es un ejemplo independiente de Terraform
(`main.tf`, `versions.tf`, `terraform.tfvars.example`, `README.md` propio),
pensado para ejecutarse por separado con su propio `terraform init`:

- [01_provider_config](01_provider_config/README.md): configuración básica
  del provider de OVH (endpoint y credenciales) y comprobación de que
  funcionan listando las regiones de Public Cloud disponibles del proyecto.
  Es el punto de partida antes de cualquier otro ejemplo de esta carpeta.
- [02_domain_dns_alias](02_domain_dns_alias/README.md): gestión de los
  registros DNS de un dominio ya dado de alta en la cuenta OVH (p. ej.
  `virtlabs.es`): un registro `A` para un nombre de máquina (p. ej.
  `valinor`) y los alias de `www` y de la raíz apuntando a él. Terraform
  no registra ni compra el dominio, solo configura su zona DNS una vez
  existe.
- [03_public_cloud_instance_volume_cloud_init](03_public_cloud_instance_volume_cloud_init/README.md): crea
  una instancia de Public Cloud (Ubuntu 26.04, ~4 vCPU/8GB, 200GB de
  disco adicional, IP pública) con una clave SSH local inyectada al
  crearla. El flavor y la imagen se indican por nombre exacto
  (`flavor_name`, `image_name`) y se resuelven a sus `id` internos con
  data sources.
- [04_public_cloud_instance_dns](04_public_cloud_instance_dns/README.md):
  una instancia `c3-16` (8 vCPU, 16 GB, 200 GB de disco raíz, sin volumen
  adicional) con nginx y un registro DNS `A` (p. ej. `node01.virtlabs.es`)
  que apunta a su IP pública. Necesita un token con permisos sobre
  `/cloud/project/*` y `/domain/zone/*`.
- [05_public_cloud_instances_dns](05_public_cloud_instances_dns/README.md):
  como el 04 pero con un número variable de máquinas: una lista de nombres
  (`nodes`) crea, por cada uno, una instancia `c3-16` con nginx y su
  registro DNS `<nombre>.<dominio>`, con `for_each` por nombre.
- [06_public_cloud_instances_module](06_public_cloud_instances_module/README.md):
  lo mismo que el 05, pero cada nodo es una llamada al módulo
  reutilizable [`modules/node`](modules/node/) (instancia + registro DNS +
  cloud-init).

Esta carpeta se irá ampliando con más ejemplos (redes privadas,
redes privadas, Kubernetes managed, etc.), cada uno en su propia subcarpeta
numerada siguiendo este mismo patrón.

## Crear las credenciales de la API desde la consola web de OVH

El provider de Terraform no usa tu usuario/contraseña del Manager, sino un
token de la API formado por tres valores: `Application Key`,
`Application Secret` y `Consumer Key`. A continuación se explica cómo
generarlos desde la propia web de OVH, sin usar la línea de comandos.

### 1. Averigua tu endpoint

El endpoint depende de la región de tu cuenta OVH:

| Cuenta OVH          | Endpoint        |
|---------------------|-----------------|
| ovh.com (Europa)    | `ovh-eu`        |
| ovhcloud.com (US)   | `ovh-us`        |
| ovh.ca (Canadá)     | `ovh-ca`        |

Esto determina también la URL donde crear el token (sustituye `eu` por
`us`/`ca` si no usas la cuenta europea):

- Europa: https://eu.api.ovh.com/createToken/
- US: https://api.us.ovhcloud.com/createToken/
- Canadá: https://ca.api.ovh.com/createToken/

### 2. Permisos (Rights) a marcar según lo que vayas a gestionar

En el formulario de `createToken` hay que añadir una ruta por cada
combinación de método HTTP (`GET`/`POST`/`PUT`/`DELETE`) y recurso. Esta
tabla resume qué meter según el ejemplo que vayas a usar:

| Para qué sirve                                    | Rutas a añadir (los 4 métodos: GET/POST/PUT/DELETE) | Ejemplo que lo usa |
|----------------------------------------------------|------------------------------------------------------|---------------------|
| Public Cloud (proyectos, instancias, redes...)      | `/cloud/project/*`                                   | [01_provider_config](01_provider_config/README.md), [03_public_cloud_instance_volume_cloud_init](03_public_cloud_instance_volume_cloud_init/README.md), [04_public_cloud_instance_dns](04_public_cloud_instance_dns/README.md) |
| Dominios / zonas DNS (todos los dominios)           | `/domain/zone/*`                                     | [02_domain_dns_alias](02_domain_dns_alias/README.md), [04_public_cloud_instance_dns](04_public_cloud_instance_dns/README.md) |
| Dominios / zonas DNS (acotado a un dominio concreto)| `/domain/zone/virtlabs.es/*`                         | [02_domain_dns_alias](02_domain_dns_alias/README.md), alternativa más restrictiva |

Puedes marcar varios bloques a la vez en el mismo token (p. ej. Public
Cloud + dominios) si vas a reutilizarlo para varios ejemplos, o crear un
token distinto y más restrictivo por cada finalidad. Esta carpeta se irá
ampliando con más ejemplos y, cuando corresponda, esta tabla con más
filas (una por cada nueva finalidad de permisos).

#### Token para máquinas virtuales y dominios a la vez

Para gestionar instancias y DNS con un solo token bastan estas dos reglas,
cada una con los 4 métodos (8 filas en el formulario):

- `/cloud/project/*`
- `/domain/zone/*`

#### Token acotado a un proyecto y a un dominio concreto

Si prefieres un token más restrictivo, sustituye los comodines generales
por rutas que incluyan tu proyecto y tu zona. Añade, cada una con los 4
métodos:

| Para qué                                   | Ruta                                       |
|--------------------------------------------|--------------------------------------------|
| El proyecto Public Cloud                    | `/cloud/project/<id-del-proyecto>`         |
| Recursos del proyecto (instancias, volúmenes, claves SSH, flavors, imágenes) | `/cloud/project/<id-del-proyecto>/*` |
| La zona DNS                                 | `/domain/zone/<tu-dominio>`                |
| Registros de la zona y su refresh           | `/domain/zone/<tu-dominio>/*`              |

Notas:

- **Dos rutas por recurso:** el comodín `/*` cubre lo que cuelga de la
  ruta, pero no siempre la ruta base, y Terraform consulta ambas
  (`GET /cloud/project/<id>`, `GET /domain/zone/<zona>`).
- **Solo vale para ese proyecto y ese dominio:** si usas otro, el token
  acotado devolverá `403` y habrá que crear uno nuevo.
- **Los permisos no se amplían:** sobre un token ya emitido no se pueden
  cambiar; hay que crear uno nuevo y sustituir a la vez `application_key`,
  `application_secret` y `consumer_key`.
- **Un token o dos:** uno solo es más cómodo; dos (uno por finalidad)
  limitan el daño si alguno se filtra.

### 3. Inicia sesión y crea el token

1. Entra en https://api.ovh.com/createToken/ con tu cuenta de OVH.
2. Mete el Application name (prueba), Application description (app de
   prueba) y Validity (30 días).
3. Rellena los permisos (Rights) según la tabla del punto anterior.
4. Genera el token. Obtendrás tres valores: `Application Key`,
   `Application Secret` y `Consumer Key`. **Guárdalos en un sitio seguro en
   ese momento**: el `Application Secret` y el `Consumer Key` no se vuelven
   a mostrar después.

### 4. Localiza el identificador del proyecto Public Cloud

Necesitas también el identificador del proyecto Public Cloud
(`service_name`), visible en la URL del proyecto en el
[panel de control de OVH](https://www.ovh.com/manager/#/public-cloud) —
desde el selector de proyectos tienes un icono para copiar el id del
proyecto — o mediante la API `GET /cloud/project`.

### 5. Usarlas con Terraform

Con esos cuatro valores (endpoint, application key, application secret,
consumer key) y el `Project ID`, ya puedes rellenar el
`terraform.tfvars` de cualquiera de los ejemplos de esta carpeta — empieza
por [01_provider_config](01_provider_config/README.md), que solo configura
el provider y comprueba que las credenciales funcionan.

**Importante**: nunca subas `terraform.tfvars` ni el `Application Secret`/
`Consumer Key` a un repositorio ni a ningún sitio público; cada ejemplo
incluye un `.gitignore` que ya excluye `terraform.tfvars`.

### 6. Revocar o regenerar el token

Si necesitas revocar las credenciales (por ejemplo si se han filtrado),
hazlo desde el Manager de OVH, en **Account > API Keys** (o la sección
equivalente según el idioma/versión del Manager), donde puedes ver y
eliminar los tokens de aplicación creados.
