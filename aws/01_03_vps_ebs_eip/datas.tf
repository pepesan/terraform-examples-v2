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
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name      = "virtualization-type"
    values    = ["hvm"]
  }

  owners      = ["099720109477"] # Canonical
}
