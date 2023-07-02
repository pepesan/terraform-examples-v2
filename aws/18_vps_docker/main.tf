provider "aws" {
  region = "eu-west-3"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "ssh_key_path" {
  type = string
}
variable "ssh_key_private_path" {
  type = string
}
variable "vpc_id" {
  type = string
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-docker-key-ubuntu"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "allow_docker_server" {
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

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPs from VPC"
    from_port   = 443
    to_port     = 443
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

// 16kB tamaño maximo
data "template_file" "userdata_server" {
  template = file("${path.module}/userdata_server.sh")
}



resource "aws_instance" "docker_server" {
  count         = 1
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  availability_zone = "eu-west-3a"
  key_name = aws_key_pair.deployer.key_name
  user_data              = data.template_file.userdata_server.rendered
  vpc_security_group_ids = [
    aws_security_group.allow_docker_server.id
  ]
  tags = {
    Name = "rke-server-instance-${count.index}"
  }
  root_block_device {
    volume_size = 80
  }
  # ejecución de comandos desde la maquina que lanza terraform
  provisioner "local-exec" {
    command = "echo The ssh id is ${self.id}"
  }
  connection {
    type = "ssh"
    user = "ubuntu"
    host = self.public_ip
    private_key = file(var.ssh_key_private_path)
  }

  provisioner "remote-exec" {
    inline = [
      "echo desplegado >> /tmp/terraform.txt"
    ]
  }
}


output "server_ips_instance" {
  value = aws_instance.docker_server[*].public_ip
}


output "ssh_server_with_public_ips" {
  value = [for instance in aws_instance.docker_server : "ssh ubuntu@${instance.public_ip}"]
}
