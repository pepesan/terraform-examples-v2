# Uso de variables en Terraform
En este módulo, se utilizan variables para configurar la conexión SSH a la instancia EC2.
1. `ssh_key_path`: Esta variable se utiliza para especificar la ruta al archivo de clave SSH que se utilizará para conectarse a la instancia EC2. Asegúrate de proporcionar la ruta correcta a tu archivo de clave SSH.
2. `key_name `: Esta variable se utiliza para especificar el nombre de la clave SSH que se ha creado en AWS. Asegúrate de que el nombre de la clave coincida con el nombre de la clave que has creado en AWS.

# Copia el fichero terraform.tfvars.example a terraform.tfvars y actualiza las variables con los valores correspondientes:
```bash
cp terraform.tfvars.example terraform.tfvars
```
# Ejecuta el ciclo de vida de Terraform para desplegar la infraestructura:
```bash
terraform init
terraform plan
terraform apply
```
