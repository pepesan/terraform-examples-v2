provider "aws" {
  region = "eu-west-3"
}
variable "ssh_key_path" {}
variable "availability_zone" {}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}
variable "project_name" {
  type = string
  default = ""
}

resource "aws_security_group" "instance" {
  name = "${var.project_name}-example-instance"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
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
  vpc_id      = data.aws_vpc.default.id
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

data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



resource "aws_security_group" "alb" {
  name = "${var.project_name}-example-alb"
  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name               = "${var.project_name}-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "asg" {
  name     = "${var.project_name}-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    # values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-ubuntu-${var.project_name}"
  public_key = file(var.ssh_key_path)
}

# resource "aws_launch_configuration" "example" {
#   image_id        = data.aws_ami.ubuntu.id
#   instance_type   = "t3.micro"
#   security_groups = [
#     aws_security_group.instance.id,
#     aws_security_group.instance_ssh.id
#   ]
#   key_name = aws_key_pair.deployer.key_name
#   user_data = templatefile(
#     # path
#     "${path.module}/userdata.sh",
#     # variables para la plantilla
#     # { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"] }
#     {}
#   )
#   # Required when using a launch configuration with an ASG.
#   lifecycle {
#     create_before_destroy = true
#   }
# }
resource "aws_launch_template" "example" {
  name = "${var.project_name}-launch-template"
  key_name = aws_key_pair.deployer.key_name
  instance_type = "t3.micro"
  # Imagen de Ubuntu 24.04
  image_id = data.aws_ami.ubuntu.id
  # Detalles del bloque de almacenamiento
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp3"
    }
  }
  vpc_security_group_ids = [
    aws_security_group.instance.id,
    aws_security_group.instance_ssh.id
  ]
  # Datos de usuario para inicializar la instancia
  user_data = base64encode(templatefile(
    # path
    "${path.module}/userdata.sh",
    # variables para la plantilla
    # { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"] }
    {}
  ))
}
# resource "aws_launch_template" "example" {
#   name = "example-launch-template"
#   name_prefix     = "test"
#   # Configuración de la instancia
#   instance_type = "t3.micro"
#   key_name = aws_key_pair.deployer.key_name
#   # Imagen de Ubuntu 24.04
#   image_id = data.aws_ami.ubuntu.id
#
#   # Datos de usuario para inicializar la instancia
#   user_data = base64encode(templatefile(
#     # path
#     "${path.module}/userdata.sh",
#     # variables para la plantilla
#     # { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"] }
#     {}
#   ))
#
#   # Configuración de red
#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [
#       aws_security_group.instance.id,
#       aws_security_group.instance_ssh.id
#     ]
#   }
#
#   # Detalles del bloque de almacenamiento
#   block_device_mappings {
#     device_name = "/dev/sda1"
#     ebs {
#       volume_size = 8
#       volume_type = "gp3"
#     }
#   }
#
#   # Etiquetas opcionales para la instancia
#   tag_specifications {
#     resource_type = "instance"
#     tags = {
#       Name = "ExampleInstance"
#     }
#   }
# }


resource "aws_autoscaling_group" "example" {
  #launch_configuration = aws_launch_configuration.example.name
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  vpc_zone_identifier  = data.aws_subnets.default.ids
  #availability_zones    = [var.availability_zone]
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  termination_policies  = ["OldestInstance"]
  desired_capacity      = 2
  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-example"
    propagate_at_launch = true
  }
  # ignora el tamaño actual al redesplegar
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}


output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}

