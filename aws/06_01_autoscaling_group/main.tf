provider "aws" {
  region = var.region_name
}

variable "region_name" {
  default = "eu-west-3"
}
variable "project_name" {
  default = ""
}
variable "ssh_key_path" {
  default = ""
}

variable "vpc_id" {
  type = string
}

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


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name      = "name"
    # values    = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name      = "virtualization-type"
    values    = ["hvm"]
  }

  owners      = ["099720109477"] # Canonical
}

resource "aws_key_pair" "deployer-key" {
  key_name      = "${var.project_name}-deployer-key"
  public_key    = file(var.ssh_key_path)
}
resource "aws_security_group" "instance" {
  name = "${var.project_name}-example-instance"
  vpc_id      = data.aws_vpc.selected.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_ssh" {
  name = "${var.project_name}-example-instance-ssh"
  vpc_id      = data.aws_vpc.selected.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_launch_configuration" "terraform_autoscale" {
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instance_ssh.id,
  aws_security_group.instance.id]
  key_name = aws_key_pair.deployer-key.key_name

  lifecycle {
    create_before_destroy = true
  }
}




resource "aws_autoscaling_group" "terraform_autoscale" {
  name = "terraform-asg"
  launch_configuration = aws_launch_configuration.terraform_autoscale.name
  max_size = 5
  min_size = 2
  desired_capacity = 2
  vpc_zone_identifier = data.aws_subnets.example.ids
}