

resource "aws_key_pair" "deployer-key" {
  key_name      = "${var.project_name}-deployer-key"
  public_key    = file(var.ssh_key_path)
}



resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_${var.project_name}"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC ${var.project_name}"
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
    name        = "allow_http-${var.project_name}"
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

resource "aws_security_group" "allow_lb" {
  name        = "allow_lb-${var.project_name}"
  description = "Allow lb inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "lb from VPC"
    from_port   = 30000
    to_port     = 33000
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
    Name = "allow_lb"
  }
}
resource "aws_instance" "web" {
  count = var.count_value
  ami           = data.aws_ami.ubuntu.id
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  root_block_device {
    volume_size = var.instance_ebs_size
  }

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id,
    aws_security_group.allow_lb.id
  ]
  user_data = templatefile(
    # path
    "${path.module}/userdata.sh",
    # variables para la plantilla
    # { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"] }
    {}
  )
  key_name      = aws_key_pair.deployer-key.key_name
  tags          = {
    Name = "${var.project_name}-web-instance-${count.index}"
  }
}





