


variable "ssh_key_path" {
  type = string
  description = "Path to the SSH public key file"
  default = "~/.ssh/id_ed25519.pub"
}
variable "ssh_key_name" {
  type = string
  description = "Name for the SSH key in Contabo"
  default = "clave-ssh-moria-ed25519"
}

variable "root_password" {
  type = string
  description = "The root password for the Contabo instance"
}

variable "password_name" {
  type = string
  description = "Name for the root password in Contabo"
  default = "root-password-moria"
}


resource "contabo_secret" "ssh_key" {
  name  = var.ssh_key_name
  value = file(var.ssh_key_path)  # tu ruta a clave pública
  type  = "ssh"
}

resource "contabo_secret" "root_password" {
  name  = var.password_name
  value = var.root_password
  type  = "password"
}