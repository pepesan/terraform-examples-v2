# Ejemplo de importación de recursos en Terraform
## Requisitos:
Tener docker instalado y en ejecución.

### Crear un contenedor de nginx
```bash
docker run --name hashicorp-learn --detach --publish "0.0.0.0:8080:80" nginx:latest
```

Extraer el ID del contenedor

## Pasos para importar recursos existentes en Terraform:
### Inicializar el directorio de trabajo
```bash
terraform init
```
### Modificar el fichero main.tf para añadir ID del contenedor
```hcl
import {
  id = "ID del contenedor Docker a importar"
  to = docker_container.web
}
```
### Importar el recurso a Terraform
```bash
terraform plan -generate-config-out=generated.tf
```

Habrá generado el ficheor generated.tf con la configuración del recurso importado, pero aún no se ha aplicado ningún cambio.
### Aplicar los cambios a la infraestructura
```bash
terraform apply
```
### Verificar que el recurso se ha importado correctamente
```bash
terraform state list
```
