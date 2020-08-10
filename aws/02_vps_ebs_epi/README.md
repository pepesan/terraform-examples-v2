# Ejemplo de uso de Terraform 02_vps_ebs_epi_
En este ejemplo crearemos una máquina en ec2 simple con una clave SSH

# Configuración de AWS CLI
[Tenemos una guía para poder gestionar las credenciales de AWS](https://cursosdedesarrollo.com/2020/08/infraestructura-uso-de-terraform-instalacion-y-configuraciones-basicas/)

# Inicialización del despliegue
<code>$ terraform init</code>
# Planificación del despliegue
<code>$ terraform plan</code>
# Despliegue de la infraestructura
<code>$ terraform apply</code>
# Conexión SSH
<code>ssh -l ubuntu EIP</code>
# Destrucción de la infraestructura
<code>$ terraform destroy</code>