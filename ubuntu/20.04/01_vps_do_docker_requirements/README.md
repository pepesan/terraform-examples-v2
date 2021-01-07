# Ejemplo de uso de Terraform 01_vps_do_docker_requirements
En este ejemplo crearemos una máquina en digitalocean con una clave SSH y un volumen asociado, además instalaremos los requisitos básicos de docker y el volumen se utilizará para albergar los datos de docker

# Configuración de Digital Ocean
[Tenemos una guía para poder gestionar las credenciales de Digital Ocean](https://cursosdedesarrollo.com/2020/08/infraestructura-uso-de-terraform-instalacion-y-configuraciones-basicas/)
# Copia el fichero terraform.tfvars.examples
<code>cp terraform.tfvars.example terraform.tfvars</code>

Edita el fichero terraform.tfvars y pon tus propios valores, sobre todo el api token y la clave ssh


# Inicialización del despliegue
<code>$ terraform init</code>
# Planificación del despliegue
<code>$ terraform plan</code>
# Despliegue de la infraestructura
<code>$ terraform apply</code>
# Destrucción de la infraestructura
<code>$ terraform destroy</code>