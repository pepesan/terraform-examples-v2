# Terraform Sensitive & Ephemeral Data Demo

Este proyecto demuestra cómo gestionar datos sensibles en Terraform siguiendo las prácticas descritas en la documentación oficial.

Incluye ejemplos de:

* Uso de `sensitive`
* Uso de `ephemeral`
* Paso de datos sensibles entre módulos
* Diferencias entre datos ocultos y datos no persistidos

---

## Estructura del proyecto

```
30_sensite_data/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    └── session/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Objetivo

Mostrar cómo Terraform trata los datos sensibles en dos niveles:

| Tipo      | Visible en CLI | Guardado en state | Uso principal            |
| --------- | -------------- | ----------------- | ------------------------ |
| sensitive | ❌ oculto       | ✅ sí              | contraseñas persistentes |
| ephemeral | ❌ oculto       | ❌ no              | tokens temporales        |

---

## 1. Datos sensibles (`sensitive`)

Ejemplo:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

### Comportamiento

* Terraform oculta el valor en:

    * `terraform plan`
    * `terraform apply`
    * `terraform output`
* ❗ **Pero sigue guardado en el state**

Ejemplo de output:

```hcl
output "db_password_sensitive" {
  value     = var.db_password
  sensitive = true
}
```

---

## 2. Datos efímeros (`ephemeral`)

Ejemplo:

```hcl
variable "session_token" {
  type      = string
  sensitive = true
  ephemeral = true
}
```

### Comportamiento

* No aparece en:

    * plan
    * state
* Solo existe durante la ejecución

👉 Ideal para:

* tokens temporales
* credenciales de sesión
* secrets de corta duración

---

## 3. Uso en módulos

Terraform **no permite outputs efímeros en el módulo raíz**, pero sí en módulos hijo.

### Ejemplo en módulo hijo

```hcl
output "session_token" {
  value     = local.token_copy
  sensitive = true
  ephemeral = true
}
```

Esto permite:

* usar el valor internamente
* evitar persistencia en state

---

## 4. Derivaciones seguras

Puedes trabajar con valores sensibles sin exponerlos:

```hcl
output "token_preview" {
  value = "token-length-${length(local.token_copy)}"
}
```

✔ Se usa el dato
❌ No se expone el valor real

---

## Cómo ejecutar

```bash
terraform init
terraform plan
terraform apply
```

---

## Qué observar

Después de ejecutar:

* `db_password_sensitive` aparece como:

  ```
  (sensitive value)
  ```


---

## Consideraciones importantes

### 1. `sensitive` NO protege el state

Aunque el valor se oculta en CLI:

* sigue en `terraform.tfstate`
* debe protegerse el backend (S3, remote, etc.)

---

### 2. `ephemeral` tiene limitaciones

Solo puede usarse en:

* variables
* outputs de módulos hijo
* bloques compatibles

No puedes:

* usarlo libremente en cualquier output del root module
* persistirlo intencionadamente

---

### 3. Comandos que exponen secretos

Evita usar:

```bash
terraform output -json
terraform output -raw
```

Pueden mostrar valores sensibles en claro.

---

## Resumen rápido

| Característica    | sensitive | ephemeral         |
| ----------------- | --------- | ----------------- |
| Oculta en CLI     | ✅         | ✅                 |
| Guardado en state | ✅         | ❌                 |
| Uso típico        | passwords | tokens temporales |
| Persistencia      | sí        | no                |

---

## Cuándo usar cada uno

Usa `sensitive` cuando:

* necesitas guardar el valor
* forma parte de la infraestructura

Usa `ephemeral` cuando:

* el valor es temporal
* no debe persistirse nunca
* es un secreto de sesión

---

## Conclusión

Terraform diferencia claramente entre:

* **ocultar datos (`sensitive`)**
* **no almacenarlos (`ephemeral`)**

Usarlos correctamente es clave para:

* seguridad
* cumplimiento
* evitar fugas de secretos

---

Si quieres ampliar este ejemplo, se puede añadir:

* integración con AWS Secrets Manager
* uso de `ephemeral` con recursos reales
* backend remoto seguro (S3 + KMS)

---
