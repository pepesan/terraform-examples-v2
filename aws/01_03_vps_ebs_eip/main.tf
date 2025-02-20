

resource "aws_key_pair" "deployer-key" {
  key_name      = "${var.project_name}-deployer-key"
  public_key    = file(var.ssh_key_path)
}


resource "aws_ebs_volume" "web" {
  availability_zone = var.availability_zone
  size              = 4
  type = "gp3"
  encrypted =   true
  tags = {
    Name = "${var.project_name}-web-ebs"
  }
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
resource "aws_security_group" "allow_https" {
  name        = "allow_https-${var.project_name}"
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


// 16kB tamaño maximo
# data "template_file" "userdata" {
#   template = file("${path.module}/userdata.sh")
# }

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  availability_zone = var.availability_zone
  instance_type = var.instance_type
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id,
    aws_security_group.allow_https.id
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
    Name = "${var.project_name}-web-instance"
  }
}

resource "aws_eip" "eip" {
  instance      = aws_instance.web.id
  # corrección de deprecated
  domain = "vpc"
  # vpc           = true
  tags          = {
    Name        = "${var.project_name}-web-epi"
  }
}
resource "aws_volume_attachment" "web" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.web.id
  instance_id = aws_instance.web.id
}





