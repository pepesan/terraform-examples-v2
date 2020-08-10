variable "project_name" {}
variable "region_name" {}
variable "availability_zone" {}
variable "vpc_id"{}

provider "aws" {
  region      = "eu-west-3"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name      = "name"
    values    = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name      = "virtualization-type"
    values    = ["hvm"]
  }

  owners      = ["099720109477"] # Canonical
}

variable "ssh_key" {}

resource "aws_key_pair" "deployer" {
  key_name      = "${var.project_name}-deployer-key"
  public_key    = var.ssh_key
}


resource "aws_ebs_volume" "web" {
  availability_zone = var.availability_zone
  size              = 4
  tags = {
    Name = "${var.project_name}-web-ebs"
  }
}
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
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
    Name = "allow_tls"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  availability_zone = var.availability_zone
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  key_name      = aws_key_pair.deployer.key_name
  tags          = {
    Name = "${var.project_name}-web-instance"
  }
}


resource "aws_eip" "eip" {
  instance      = aws_instance.web.id
  vpc           = true
  tags          = {
    Name        = "${var.project_name}-web-epi"
  }
}

resource "aws_volume_attachment" "web" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web.id
  instance_id = aws_instance.web.id
}

output "instance_ip" {
  description = "The public ip for the instance"
  value       = aws_instance.web.public_ip
}
output "eip_ip" {
  description = "The eip ip for ssh access"
  value       = aws_eip.eip.public_ip
}



