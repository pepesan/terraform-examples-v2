provider "aws" {
  region = "eu-west-3"
}

data "aws_region" "current" { }

output "salida-region" {
  value = data.aws_region.current.name
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}



output "salida-az" {
  value = data.aws_availability_zones.available
}

output "salida-az-names" {
  value = data.aws_availability_zones.available.names
}
