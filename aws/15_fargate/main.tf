# Fichero main.tf

provider "aws" {
  region = "eu-west-3"
}

data "aws_availability_zones" "aws-az" {
  state = "available"
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "vpc-main"
  cidr                 = "10.0.0.0/16"
  azs                  = [data.aws_availability_zones.aws-az.names]
  private_subnets      = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnets       = ["10.0.100.0/24", "10.0.101.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  tags = {
    Terraform   = "true",
    Environment = "dev"
  }
}

resource "aws_ecs_task_definition" "task" {
  family                        = "service"
  network_mode                  = "awsvpc"
  requires_compatibilities      = ["FARGATE", "EC2"]
  cpu                           = 512
  memory                        = 2048
  container_definitions         = jsonencode([
    {
      name      = "nginx-app"
      image     = "nginx:latest"
      cpu       = 512
      memory    = 2048
      essential = true  # if true and if fails, all other containers fail. Must have at least one essential
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_security_group" "allow_ports" {
  name        = "allow_ssh_http_https"
  description = "Allow inbound SSH, HTTP and HTTPS traffic and http from any IP"
  vpc_id      = module.vpc.vpc_id

  #ssh access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_ecs_service" "service" {
  name              = "service"
  cluster           = aws_ecs_cluster.ping.id
  task_definition   = aws_ecs_task_definition.task.id
  desired_count     = 1
  launch_type       = "FARGATE"
  platform_version  = "LATEST"

  network_configuration {
    assign_public_ip  = true
    security_groups   = [aws_security_group.allow_ports.id]
    subnets           = [element(module.vpc.public_subnets,1)]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}