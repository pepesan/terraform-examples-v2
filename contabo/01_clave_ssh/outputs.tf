output "my_secret_ssh_id" {
  description = "my secret ssh id"
  value = contabo_secret.ssh_key.id
}

output "my_secret_password_id" {
  description = "my secret password id"
  value = contabo_secret.root_password.id
}