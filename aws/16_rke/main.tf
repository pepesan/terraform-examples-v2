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
  key_name   = "deployer-rke-key-ubuntu"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "allow_rke_ssh" {
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
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    description = "Kubernetes API (RKE2 agent nodes)"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    description = "Kubernetes API (RKE2 agent nodes)"
  }
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    description = "RKE2 server and agent nodes, Required only for Flannel VXLAN and Cilium CNI VXLAN"
  }
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Required only for kubelet"
  }
  ingress {
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    description = "RKE2 server nodes, etcd client port"
  }
  ingress {
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    description = "RKE2 server nodes, etcd peer port"
  }
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    description = "NodePort port range (RKE2 server and agent nodes)"
  }
  ingress {
    from_port   = 4240
    to_port     = 4240
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Cilium CNI health checks"
  }
  ingress {
    from_port   = 4240
    to_port     = 4240
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Cilium CNI health checks"
  }
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    description = "Cilium CNI health checks (RKE2 server and agent nodes)"
  }
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Calico CNI with BGP"
  }
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    description = "RKE2 server and agent nodes, Calico CNI with VXLAN"
  }
  ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Calico CNI with Typha"
  }
  ingress {
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Calico Typha health checks"
  }
  ingress {
    from_port   = 9099
    to_port     = 9099
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Calico health checks and Canal CNI health checks"
  }
  ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    description = "RKE2 server and agent nodes, Calico CNI with Typha"
  }
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    description = "RKE2 server and agent nodes, Canal CNI with VXLAN"
  }
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    description = "RKE2 server and agent nodes, Canal CNI with WireGuard IPv4"
  }
  ingress {
    from_port   = 51821
    to_port     = 51821
    protocol    = "udp"
    description = "RKE2 server and agent nodes, Canal CNI with WireGuard IPv6/dual-stack"
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
data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh")
}

resource "aws_instance" "web" {
  count         = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  key_name = aws_key_pair.deployer.key_name
  user_data              = data.template_file.userdata.rendered
  vpc_security_group_ids = [
    aws_security_group.allow_rke_ssh.id
  ]
  tags = {
    Name = "rke-instance-${count.index}"
  }
  root_block_device {
    volume_size = 20
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

output "ips_instance" {
  value = aws_instance.web[*].public_ip
}

#output "ssh" {
#  value = "ssh -l ubuntu ${aws_instance.web.public_ip}"
#}

output "ssh_with_public_ips" {
  value = [for instance in aws_instance.web : "ssh ubuntu@${instance.public_ip}"]
}