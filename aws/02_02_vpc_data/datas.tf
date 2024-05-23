variable "vpc_id" {}
# Vpc disponibles
data "aws_vpcs" "vpcs"{}

# Datos de una VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}
# subredes de una vpc por id
data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

