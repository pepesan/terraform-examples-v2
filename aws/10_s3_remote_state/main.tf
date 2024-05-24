variable "project_name" {
  type = string
  default = "cdd"
}
variable "region" {
  type = string
  default = "region"
}

variable "ssh_key_path" {
  type = string
}
variable "vpc_id" {
  type = string
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "cdd-profe-backend-tfstate"
    key            = "cdd/terraform.tfstate"
    region         = "eu-west-3"

    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-cdd-up-and-running-locks"
    encrypt        = true
  }
}


provider "aws" {
  region      = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}



resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-deployer-key"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "${var.project_name}-allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id
  ]
  tags = {
    Name = "HelloWorld-${var.project_name}"
  }
}

output "ip_instance" {
  value = aws_instance.web.public_ip
}

output "ssh" {
  value = "ssh -l ubuntu ${aws_instance.web.public_ip}"
}