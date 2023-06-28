variable "mivar" {
  default = "hola"
}
variable "apellidos"{
  default = "Vaquero"
}
output "salida-plantilla" {
  value = templatefile("user_data.tftpl", { nombre = var.mivar, apellidos = var.apellidos})
}
