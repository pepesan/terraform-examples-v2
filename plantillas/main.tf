variable "mivar" {
  default = "hola"
}
variable "apellidos"{
  default = "Vaquero"
  sensitive = true
}
output "salida-plantilla" {
  value = templatefile("user_data.tftpl", { nombre = var.mivar, apellidos = var.apellidos})
}
