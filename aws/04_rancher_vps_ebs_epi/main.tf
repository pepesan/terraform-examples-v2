variable "project_name" {}
variable "region_name" {}
variable "availability_zone" {}
variable "vpc_id"{}
variable "instance_type" {}
variable "domain_name" {}
variable "rancher_dns_name" {}
variable "hostname-prefix" {}
variable "docker_cmd" {}
provider "aws" {
  region      = var.region_name
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name      = "name"
    values    = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
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
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "allow_http" {
    name        = "allow_http"
    description = "Allow http inbound traffic"
    vpc_id      = var.vpc_id

    ingress {
      description = "http from VPC"
      from_port   = 80
      to_port     = 80
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
      Name = "allow_http"
    }
  }
resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow https inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "https from VPC"
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
    Name = "allow_https"
  }
}
resource "aws_eip" "eip" {
  instance      = aws_instance.web.id
  vpc           = true
  tags          = {
    Name        = "${var.project_name}-web-epi"
  }
}

data "template_file" "userdata" {
  template = templatefile("${path.module}/userdata.sh", {
    "hostname-prefix" = var.hostname-prefix,
    "docker_cmd" = var.docker_cmd,
    "dns_name" = "${var.rancher_dns_name}.${var.domain_name}"
  })
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id,
    aws_security_group.allow_https.id
  ]
  user_data = data.template_file.userdata.rendered
  key_name      = aws_key_pair.deployer.key_name
  tags          = {
    Name = "${var.project_name}-web-instance"
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


data "aws_route53_zone" "selected" {
  name         = "${var.domain_name}."
  private_zone = true
}

resource "aws_route53_record" "rancher" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.rancher_dns_name}.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.eip.public_ip]
}
resource "aws_route53_health_check" "rancher" {
  fqdn              = "${var.rancher_dns_name}.${var.domain_name}"
  port              = 443
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
  search_string     = "rancher"
  type              = "HTTPS_STR_MATCH"
  tags = {
    Name = "tf-test-health-check"
  }
}
output "ssh" {
  value = "ssh -l ubuntu ${aws_eip.eip.public_ip}"
}
output "url-http" {
  value = "http://${aws_eip.eip.public_ip}/"
}
output "url-https" {
  value = "https://${aws_eip.eip.public_ip}/"
}
output "rancher-url-https" {
  value = "https://${var.rancher_dns_name}.${var.domain_name}"
}



