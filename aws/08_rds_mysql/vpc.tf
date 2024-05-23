module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "vpc-main"
  cidr                 = "10.0.0.0/16"
  azs                  = [var.availability_zone_a, var.availability_zone_b]
  private_subnets      = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnets       = ["10.0.100.0/24", "10.0.101.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  tags = {
    Terraform   = "true",
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "education" {
  name       = "education-${var.subnet_group_name}"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "Education"
  }
}