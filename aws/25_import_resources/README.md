# Ejemplo de importación de recursos en Terraform

Este ejemplo muestra cómo importar un recurso existente en Terraform usando el **bloque `import`** (método nativo desde Terraform 1.5), en lugar del comando clásico `terraform import`.

## Requisitos

- Terraform >= 1.5
- Docker instalado y en ejecución

## Pasos

### 1. Crear un contenedor Docker existente

```bash
docker run --name hashicorp-learn --detach --publish "0.0.0.0:8080:80" nginx:latest
```

> **Importante:** el provider de Docker solo puede importar contenedores en ejecución. Si el contenedor está parado, arráncalo antes de continuar: `docker start <CONTAINER_ID>`

### 2. Obtener el ID completo del contenedor

El provider de Docker requiere el **ID completo** (64 caracteres), no el ID corto que muestra `docker ps`.

```bash
docker inspect hashicorp-learn --format "{{.Id}}"
```

### 3. Actualizar `main.tf` con el ID del contenedor

Reemplaza `CONTAINER_ID` en el bloque `import` con el ID obtenido en el paso anterior:

```hcl
import {
  id = "ID del contenedor Docker a importar"
  to = docker_container.web
}
```

### 4. Inicializar el directorio de trabajo

```bash
terraform init
```

### 5. Generar la configuración del recurso importado

```bash
terraform plan -generate-config-out=generated.tf
```

Terraform genera el fichero `generated.tf` con el bloque `resource "docker_container" "web"` completo, pero aún no aplica ningún cambio.

### 6. Aplicar los cambios

```bash
terraform apply
```

El recurso queda gestionado por Terraform.

### 7. Verificar que el recurso se ha importado correctamente

```bash
terraform state list
```

## Limpieza

```bash
terraform destroy
docker rm -f hashicorp-learn
```

## Diferencia entre `import` block y `terraform import`

| Característica                    | Bloque `import` (≥ 1.5)      | Comando `terraform import` |
|-----------------------------------|------------------------------|----------------------------|
| Declarativo                       | Sí                           | No                         |
| Genera configuración              | Sí (`-generate-config-out`)  | No                         |
| Se puede revisar antes de aplicar | Sí (`terraform plan`)        | No                         |