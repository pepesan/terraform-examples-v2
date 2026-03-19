
variable "root_password" {
  type = string
  description = "The root password for the Contabo instance"
}

variable "ssh_key_id" {
  type = string
  description = "The ID of the SSH key to be used for accessing the Contabo instance"
}
variable "password_id" {
  type = string
  description = "The ID of the root password to be used for accessing the Contabo instance"
}



data "contabo_secret" "ssh_key" {
  id = var.ssh_key_id
}

data "contabo_secret" "password" {
  id = var.password_id
}

# Create a new compute instance (vps/vds) in region EU, with specs of the V76 product. Also it has a contract period of 3 month
variable "instance_name" {
  default = "servidor-00"
}



resource "contabo_instance" "database_instance" {

  display_name  = var.instance_name

  # https://api.contabo.com/#tag/Instances/operation/createInstance
  # V97: 8 vCPU, 24 GB RAM, 200 GB NVME
  product_id    = "V97"

  # Datacenter region
  region        = "EU"

  # usuario con permisos de root
  default_user  = "root"
  root_password = data.contabo_secret.password.id

  # un mes
  period        = 1

  # Ubuntu 24.04
  image_id      = "d64d5c6c-9dda-4e38-8174-0ee282474d8a"

  # Clave ssh para acceder a la instancia
  ssh_keys = [
    data.contabo_secret.ssh_key.id
  ]
}

output "database_instance_public_ips" {
  value = [
    for instance in contabo_instance.database_instance :
    instance.ip_config[0].v4[0].ip
  ]
}

