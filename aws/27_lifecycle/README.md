# Ejemplo de Terraform Lifecycle

Este proyecto demuestra cómo usar el bloque `lifecycle` de Terraform


## Cómo usar este ejemplo

### 1. Inicializar Terraform

```bash
terraform init
```

Esto preparará el entorno.

---

### 2. Aplicar la configuración inicial

```bash
terraform apply
```

Confirma con `yes` cuando se solicite.

Esto creará tres recursos:

* `terraform_data.config`
* `terraform_data.deployment`
* `terraform_data.critical_record`

---

## Qué está pasando

Este ejemplo muestra tres comportamientos clave del `lifecycle`:

### 1. ignore_changes

Recurso: `terraform_data.config`

Terraform ignorará cambios en:

```text
input
```

Aunque modifiques ese valor en el código, Terraform no intentará actualizarlo.

---

### 2. create_before_destroy

Recurso: `terraform_data.deployment`

Cuando cambie la variable `app_version`, el recurso será reemplazado.

Terraform hará:

1. Crear el nuevo recurso
2. Destruir el antiguo

Esto evita interrupciones (downtime).

---

### 3. prevent_destroy

Recurso: `terraform_data.critical_record`

Terraform NO permitirá destruir este recurso.

---

## Pruebas paso a paso

### Test 1: Reemplazo con create_before_destroy

1. Edita el archivo `.tf`
2. Cambia la variable app_version:

```hcl
default = "1.0.0"
```

por:

```hcl
default = "2.0.0"
```

3. Ejecuta:

```bash
terraform plan
```

Verás que `terraform_data.deployment` será **reemplazado**.

4. Aplica cambios:

```bash
terraform apply
```

---

### Test 2: ignore_changes

1. Modifica el bloque del recurso `terraform_data.config`:

```hcl
resource "terraform_data" "config" {
  input = {
    app_name = "demo"
    owner    = "otro-equipo"
  }
}
```

2. Ejecuta:

```bash
terraform plan
```

Terraform NO detectará cambios.

---

### Test 3: prevent_destroy

1. Intenta destruir:

```bash
terraform destroy
```

Terraform fallará con un error indicando que no puede destruir `critical_record`.

---

## Nota importante

* `prevent_destroy` **solo funciona si el recurso sigue definido en el código**
  Si eliminas el bloque del `.tf`, Terraform sí podrá destruirlo.

---

## Limpieza (opcional)

Para poder destruir todo:

1. Elimina o comenta este bloque del recurso `terraform_data.critical_record`:

```hcl
lifecycle {
  prevent_destroy = true
}
```

2. Ejecuta:

```bash
terraform destroy
```

---

## Resumen

Este ejemplo demuestra:

* `ignore_changes`: ignora cambios en atributos concretos
* `create_before_destroy`: crea antes de destruir
* `prevent_destroy`: evita borrados accidentales


