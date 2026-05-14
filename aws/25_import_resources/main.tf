terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Sustituye el valor de id por el ID completo (64 chars) del contenedor Docker a importar.
# Ejecución: docker inspect hashicorp-learn --format "{{.Id}}"
import {
  id = "ID_LARGO_CONTENEDOR"
  to = docker_container.web
}

# El bloque resource se generará automáticamente en generated.tf al ejecutar:
# terraform plan -generate-config-out=generated.tf