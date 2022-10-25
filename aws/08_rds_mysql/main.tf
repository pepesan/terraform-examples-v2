provider "aws" {
  region = "eu-west-3"
}

variable "availability_zone_a" {
  default = "eu-west-3a"
}
variable "availability_zone_b" {
  default = "eu-west-3b"
}
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
  name       = "education"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "Education"
  }
}

resource "aws_security_group" "allow_rds_ports" {
  name        = "allow_rds_ports"
  description = "Allow inbound Mysql from any IP"
  vpc_id      = module.vpc.vpc_id

  #ssh access
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

variable "db_password" {
  default = "admin1234"
}
resource "aws_db_instance" "rds" {
  allocated_storage = 20
  identifier = "rds-terraform"
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "8.0.27"
  instance_class = "db.t2.micro"
  db_name = "mydb"
  username = "admin"
  password = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.allow_rds_ports.id]
  apply_immediately      = true
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name = "ExampleRDSServerInstance"
  }
}
output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.rds.address
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.rds.port
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.rds.username
}
