# Pruebas del módulo node con un provider simulado: no necesitan credenciales,
# no llaman a la API de OVH y no cuestan nada. Se ejecutan con:
#   terraform init -backend=false && terraform test
#
# LIMITACIÓN CONOCIDA (Terraform 1.15.8): el mock no puede rellenar los
# atributos "set de objetos" de los data sources (flavors, images): da un
# conjunto vacío tanto con override_data como con mock_data. El catálogo
# simulado queda, pues, siempre vacío y la precondition de flavor/imagen de la
# instancia falla en TODAS las pruebas. Por eso cada run declara
# expect_failures = [ovh_cloud_project_instance.vm] y comprueba el resto del
# plan que no depende de la instancia ni del registro: salidas (fqdn, URL) y
# validaciones de variables. Con la instancia fallida, sus atributos
# (user_data, auto_backup, IPv4...) y el registro DNS quedan sin procesar y no
# se pueden comprobar aquí: eso se revisa con el plan del 06 (catálogo real).

mock_provider "ovh" {}

# Valores válidos comunes; cada caso solo redefine lo que prueba
variables {
  project_id   = "proyecto-de-prueba"
  region       = "GRA11"
  name         = "nodo01"
  domain       = "example.com"
  ssh_key_name = "clave-de-prueba"
  flavor_name  = "c3-16"
  image_name   = "Ubuntu 26.04"
}

# Catálogo vacío (el único que el mock permite): la precondition debe fallar
run "catalogo_sin_el_flavor_ni_la_imagen" {
  command         = plan
  expect_failures = [ovh_cloud_project_instance.vm]
}

# Nombre DNS y URL
run "nombres_y_url" {
  command         = plan
  expect_failures = [ovh_cloud_project_instance.vm]

  assert {
    condition     = output.fqdn == "nodo01.example.com"
    error_message = "El fqdn debe ser <name>.<domain>"
  }

  assert {
    condition     = output.web_url == "http://nodo01.example.com"
    error_message = "La URL debe ser http://<fqdn>"
  }

}

# Nombres que no son un subdominio válido: falla la validación de la variable
run "nombre_con_mayusculas" {
  command = plan
  variables {
    name = "Nodo01"
  }
  expect_failures = [var.name]
}

run "nombre_con_guion_bajo" {
  command = plan
  variables {
    name = "nodo_01"
  }
  expect_failures = [var.name]
}

run "nombre_empieza_por_guion" {
  command = plan
  variables {
    name = "-malo"
  }
  expect_failures = [var.name]
}

run "nombre_con_punto" {
  command = plan
  variables {
    name = "a.b"
  }
  expect_failures = [var.name]
}

run "nombre_de_64_caracteres" {
  command = plan
  variables {
    name = join("", [for i in range(64) : "a"])
  }
  expect_failures = [var.name]
}

# Rotación inválida
run "rotacion_cero" {
  command = plan
  variables {
    backup_rotation = 0
  }
  expect_failures = [var.backup_rotation]
}

# Nombres válidos en el límite: la validación NO falla (solo la precondition
# del catálogo, común a todas las pruebas)
run "nombre_de_63_caracteres" {
  command         = plan
  expect_failures = [ovh_cloud_project_instance.vm]
  variables {
    name = join("", [for i in range(63) : "a"])
  }
  assert {
    condition     = length(output.fqdn) == 63 + length(".example.com")
    error_message = "63 caracteres es un nombre válido"
  }
}

run "nombre_de_un_caracter" {
  command         = plan
  expect_failures = [ovh_cloud_project_instance.vm]
  variables {
    name = "a"
  }
  assert {
    condition     = output.fqdn == "a.example.com"
    error_message = "Un solo carácter es un nombre válido"
  }
}

run "nombre_que_empieza_por_numero" {
  command         = plan
  expect_failures = [ovh_cloud_project_instance.vm]
  variables {
    name = "0abc"
  }
  assert {
    condition     = output.fqdn == "0abc.example.com"
    error_message = "Empezar por número es válido"
  }
}
