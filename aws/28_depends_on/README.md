# Ejemplo de Dependencias de Terraform

Este proyecto demuestra cómo funcionan las 
**dependencias implícitas y explícitas** en Terraform utilizando 
únicamente recursos nativos (`terraform_data`) y un módulo local.


---

## Estructura del proyecto

```text
.
├── main.tf
└── modules
    └── report
        └── main.tf
```

---

## Cómo usar este ejemplo

### 1. Inicializar Terraform

```bash
terraform init
```

---

### 2. Ver el plan de ejecución

```bash
terraform plan
```

---

### 3. Aplicar los cambios

```bash
terraform apply
```

Confirma con `yes` cuando se solicite.

---

## Qué demuestra este ejemplo

### 1. Dependencia implícita

```hcl
database_name = terraform_data.database.output.name
```

El recurso `backend` usa un atributo de `database`.

- Terraform detecta automáticamente esta relación
- `database` se crea antes que `backend`

---

### 2. Ejecución en paralelo

```hcl
resource "terraform_data" "logging" {
  
}
```

Este recurso no depende de nadie.

Terraform puede crearlo en paralelo con otros recursos

---

### 3. Dependencia explícita (`depends_on`)

```hcl
depends_on = [
  terraform_data.backend,
  terraform_data.logging
]
```

El recurso `smoke_tests` no referencia directamente a otros recursos,
pero necesita que existan antes.

`depends_on` fuerza el orden de ejecución

---

### 4. Dependencias en módulos

```hcl
module "report" {
  depends_on = [
    terraform_data.backend,
    terraform_data.smoke_tests
  ]
}
```

Los módulos también pueden tener dependencias explícitas.

El módulo `report` se ejecutará después de esos recursos

---

## Orden real de ejecución

Terraform **NO sigue el orden en el archivo `.tf`**.

Construye un grafo de dependencias, por lo que el flujo será:

1. `database` y `logging` pueden crearse en paralelo
2. `backend` espera a `database`
3. `smoke_tests` espera a `backend` y `logging`
4. `report` espera a `backend` y `smoke_tests`

---

## Pruebas recomendadas

### Test 1: Cambiar el orden del código

Reordena los bloques dentro de `main.tf` (por ejemplo, pon `backend` arriba del todo).

```bash
terraform plan
```

Verás que el comportamiento NO cambia

---

### Test 2: Quitar `depends_on`

Elimina este bloque:

```hcl
depends_on = [
  terraform_data.backend,
  terraform_data.logging
]
```

Ejecuta:

```bash
terraform plan
```

Terraform ya no garantiza el orden de `smoke_tests`

---

### Test 3: Añadir dependencia innecesaria

Añade un `depends_on` extra a cualquier recurso:

```hcl
depends_on = [terraform_data.database]
```

Terraform será más lento porque reduce paralelismo

---

## Buenas prácticas

* Usa **referencias directas** siempre que sea posible → generan dependencias implícitas
* Usa `depends_on` **solo cuando sea necesario**
* Evita abusar de `depends_on` → reduce el paralelismo y hace el plan más lento

---

## Limpiar recursos

```bash
terraform destroy
```

Confirma con `yes`.

---

## Resumen

* Terraform usa un **grafo de dependencias**, no el orden del archivo
* Referenciar atributos crea **dependencias implícitas**
* `depends_on` permite definir **dependencias explícitas**
* Menos `depends_on` → mejor paralelismo → ejecuciones más rápidas

---
