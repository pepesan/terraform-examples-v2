# Fichero main.tf

provider "aws" {
  region = "eu-west-3"
}
# variable path clave ssh
variable "ssh_key_path" {}
# variable del Id de la VPC
variable "vpc_id" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "vpc-main"
  cidr                 = "10.0.0.0/16"
  azs                  = [var.availability_zone]
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

# Recurso de clave SSH en AWS
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "allow_ports" {
  name        = "allow_ssh_http_https"
  description = "Allow inbound SSH, HTTP and HTTPS traffic and http from any IP"
  vpc_id      = module.vpc.vpc_id

  #ssh access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# RHEL 8.5
data "aws_ami" "rhel_8_5" {
  most_recent = true
  owners = ["309956199498"] // Red Hat's Account ID
  filter {
    name   = "name"
    values = ["RHEL-8.5*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# variable de la zona de disponibilidad
variable "availability_zone" {}
#definición del recurso EBS
resource "aws_ebs_volume" "web" {
  availability_zone = var.availability_zone
  size              = 4
  type = "gp3"
  encrypted =   true
  tags = {
    Name = "web-ebs"
  }
}

// 16kB tamaño maximo
data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh")
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.rhel_8_5.id
  availability_zone = var.availability_zone
  instance_type = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  user_data              = data.template_file.userdata.rendered
  vpc_security_group_ids = [aws_security_group.allow_ports.id]
  subnet_id              = element(module.vpc.public_subnets,1)
  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_volume_attachment" "web" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web.id
  instance_id = aws_instance.web.id
}

resource "aws_eip" "eip" {
  instance      = aws_instance.web.id
  vpc           = true
  tags          = {
    Name        = "web-epi"
  }
}

output "ip_instance" {
  value = aws_instance.web.public_ip
}

output "eip_ip" {
  description = "The eip ip for ssh access"
  value       = aws_eip.eip.public_ip
}

output "ssh" {
  value = "ssh -l ec2-user ${aws_instance.web.public_ip}"
}
output "ssh_eip" {
  value = "ssh -l ec2-user ${aws_eip.eip.public_ip}"
}


