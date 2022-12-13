# manejo listados

variable "listado" {
  default = [1,2,3]
}

output "salida-listado" {
  value = element(var.listado, 1)
}

# Manejo mapas
variable "mimapa" {
  default = {
    clave = "valor"
  }
}

output "salida-mapa" {
  value = lookup(var.mimapa, "clave", "default")

}

# split cadena
variable "micadena" {
  default = "1,2,3"
}

output "salida-split" {
  value = split(",", var.micadena)
}

variable "list-to-join" {
  default = [1,2,3]
}

output "salida-contains" {
  value = contains(var.list-to-join, 3 )
}

output "salida-join" {
  value = join(",", var.list-to-join)
}

output "salida-lenght" {
  value = length(var.list-to-join)
}

variable "nombre" {
  default = "david"
}

output "salida-upper" {
  value = upper(var.nombre)
}

output "salida-title" {
  value = title(var.nombre)
}

output "salida-replace" {
  value = replace(var.nombre, "a","A")
}

output "salida-length-cadena" {
  value = length(var.nombre)
}

output "salida-base64" {
  value = base64encode("asdsa añsldk ñ")
}

# max
output "salida-max" {
  value = max(1,2,3)
}

# timestamp
locals {
  time = timestamp()
}
output "salida-time" {
  value = local.time
}

output "salida-format" {
  value = formatdate("DD MM YYYY hh:mm ZZZ",local.time )
}

variable "environment" {
  default = {
    "test" = "us-east-1"
    "prod" = "us-west-2"
  }
}

variable "availzone" {
  description = "Availability Zones Mapping"
  default = {
    "us-east-1" = "us-east-1a,us-east-1b,us-east-1c"
    "us-west-2" = "us-west-2a,us-west-2b,us-east-1c"
  }
}
# To capture one AZ, first use the lookup()function to get the list of comma-separated values,
# and then split it with a comma ( ,) and the split() function.
# Finally, use the element() function to capture the defined index of choice.
output "availabiltyzones" {
  value = element(split(",", lookup(var.availzone,var.environment.prod)), 1)
}