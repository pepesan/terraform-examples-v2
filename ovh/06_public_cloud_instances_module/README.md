# Ejemplo de uso de Terraform 06_public_cloud_instances_module

Hace lo mismo que el [05](../05_public_cloud_instances_dns/README.md): una
máquina de OVH Public Cloud (Ubuntu 26.04, flavor c3-16) con nginx por
cloud-init **por cada nombre de la lista `nodes`**, una clave SSH compartida y
un registro DNS `<nodo>.<domain>` por máquina. La diferencia es la
estructura: cada nodo es una llamada al **módulo** [`../modules/node`](../modules/node/),
y aquí solo queda lo común (clave SSH, lista de nodos, salidas).

Los ejemplos 04 y 05 no usan el módulo; siguen siendo autocontenidos.

## Cómo está repartido

| Dónde | Qué contiene |
|-------|--------------|
| `../modules/node` | Una instancia + su registro A + cloud-init, con la resolución y validación de flavor/imagen |
| `main.tf` | La clave SSH y `module "node"` con `for_each = toset(var.nodes)` |
| `outputs.tf` | Agrega las salidas de cada módulo y construye `ssh_connection` |

Cada nodo queda en `module.node["nodo01"]`, `module.node["nodo02"]`...
Quitar un nombre de `nodes` destruye solo ese módulo.

## Qué crea (con `nodes = ["nodo01","nodo02","nodo03"]`: 8 recursos)

- 1 `ovh_cloud_project_ssh_key` compartida.
- Por nodo: 1 `ovh_cloud_project_instance` y 1 `ovh_domain_zone_record`.
- 1 `local_file` con el inventario CSV (ver abajo).

**Coste:** cada nodo c3-16 ronda los 0,18 €/h (sin IVA); 3 nodos ≈ 0,55 €/h.
Haz `terraform destroy` al terminar.

## Inventario CSV (ip → fqdn)

Además del output `nodes`, el ejemplo escribe un fichero CSV con una fila por
nodo, ordenadas por nombre (`nodos.csv` por defecto, cambiable con
`inventory_csv_path`, relativo a este directorio):

```csv
ip,fqdn
203.0.113.10,nodo01.virtlabs.es
203.0.113.11,nodo02.virtlabs.es
```

- El contenido también sale por `terraform output -raw inventory_csv` y la
  ruta absoluta por `inventory_csv_path`.
- El fichero se reescribe si cambia alguna IP y se borra con `terraform destroy`.
- Contiene IPs reales, por eso `*.csv` está en el `.gitignore`: no lo
  versiones.
- Usa el provider `hashicorp/local` (fijado en `versions.tf`).

## Flavor por nodo

`flavor_name` es el flavor común; `node_flavors` permite otro distinto para
nodos concretos (los ausentes usan `flavor_name`):

```hcl
nodes        = ["nodo01", "nodo02", "nodo03"]
flavor_name  = "c3-16"
node_flavors = { nodo03 = "c3-8" }   # nodo03 más pequeño
```

Las claves de `node_flavors` deben ser nombres de `nodes`. El output `nodes`
incluye el `flavor` de cada nodo. Cambiar el flavor de un nodo existente
**recrea** esa instancia y su IP.

## Cuotas: cuánto necesitas

La cuota (por proyecto y región) se agota por vCPU, RAM e instancias; el
`apply` falla con `409 ... ram quota ... reached` al superar la primera.
Suma por nodo según su flavor:

| Flavor | vCPU | RAM | Instancias para 10 nodos: vCPU / RAM | Para 20 nodos: vCPU / RAM |
|--------|------|-----|--------------------------------------|---------------------------|
| `c3-16` | 8 | 16 GB | 80 / 160 GB | 160 / 320 GB |
| `c3-8` | 4 | 8 GB | 40 / 80 GB | 80 / 160 GB |
| `c3-4` | 2 | 4 GB | 20 / 40 GB | 40 / 80 GB |

`c3-16` es el único flavor de la tabla comprobado contra el catálogo del
proyecto; las cifras de `c3-8` y `c3-4` siguen la serie `c3` y conviene
confirmarlas con el data source de flavors antes de pedir cuota. La cuota de
RAM del proyecto fue de 44 000 MB (2 nodos `c3-16`). Aumentarla desde el
Manager implica **añadir crédito** al proyecto (no reembolsable, se consume
facturando ese proyecto).

## Si vienes del 05

El 06 tiene su propio estado y direcciones distintas (`module.node[...]`):
no comparte recursos con el 05. No ejecutes ambos con los mismos nombres de
nodo y de clave a la vez: la clave SSH y los registros DNS chocarían. Cambia
`nodes` o `ssh_key_name`, o destruye uno antes de crear el otro.

## Uso

```bash
cp terraform.tfvars.example terraform.tfvars   # y edita tus valores
terraform init
terraform plan
terraform apply
terraform output nodes
terraform destroy
```

Credenciales, permisos del token, puertos, cambios que recrean la máquina y
catálogo de flavors: igual que en el [05](../05_public_cloud_instances_dns/README.md)
y el [README general](../README.md).

## Credenciales por variables de entorno (opcional)

Las cuatro variables `ovh_*` valen `null` por defecto: si no están en
`terraform.tfvars`, el provider lee `OVH_ENDPOINT`, `OVH_APPLICATION_KEY`,
`OVH_APPLICATION_SECRET` y `OVH_CONSUMER_KEY` del entorno.

## Entradas del módulo

`project_id`, `region`, `name`, `domain`, `ssh_key_name`, `flavor_name`,
`image_name`, `backup_enabled`, `backup_cron`, `backup_rotation` y `dns_ttl`
(ver `../modules/node/variables.tf`). Salidas: `fqdn`, `instance_id`,
`public_ip`, `web_url`, `dns_record_id`, `flavor_id`, `image_id`.
