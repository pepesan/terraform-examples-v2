data "aws_ami" "debian" {
  most_recent = true

  filter {
    name      = "name"
    # values    = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["debian-12-amd64-*"] # debian 12
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name      = "virtualization-type"
    values    = ["hvm"]
  }

  owners      = ["136693071363"] # Debian
}
