# upper() y lower() — cambiar mayúsculas/minúsculas

variable "project_name" {
  default = "demoProject"
}


output "project_upper" {
  value = upper(var.project_name)
}

output "project_lower" {
  value = lower(var.project_name)
}

# length() — longitud de una lista
variable "regions" {
  default = ["eu-west-1", "eu-west-2", "eu-west-3"]
}

output "region_count" {
  value = length(var.regions)
}

# join() — unir elementos de una lista
variable "names" {
  default = ["app", "api", "worker"]
}

output "service_list" {
  value = join("-", var.names)
}

# split() — dividir un string
variable "environment_string" {
  default = "demo-dev-eu"
}

output "environment_parts" {
  value = split("-", var.environment_string)
}

# merge() — unir mapas
variable "default_tags" {
  default = {
    ManagedBy = "terraform"
    Owner     = "team-dev"
  }
}

variable "extra_tags" {
  default = {
    Environment = "dev"
  }
}

output "all_tags" {
  value = merge(var.default_tags, var.extra_tags)
}

# contains() — comprobar si un valor está en una lista
variable "allowed_envs" {
  default = ["dev", "staging", "prod"]
}

variable "environment" {
  default = "dev"
}

output "is_valid_environment" {
  value = contains(var.allowed_envs, var.environment)
}