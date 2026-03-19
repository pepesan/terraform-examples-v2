output "generated_name" {
  value = random_pet.app.id
}

output "app_config" {
  value = terraform_data.app_config.output
}