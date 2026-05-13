# ─────────────────────────────────────────────────────────────────────────────
# ESTRATEGIA 1 (activa): buscar VPC por ID
# ─────────────────────────────────────────────────────────────────────────────
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# ─────────────────────────────────────────────────────────────────────────────
# ESTRATEGIA 2 (alternativa): buscar VPC por tag Name
# Descomenta y comenta la estrategia 1 cuando tu VPC tenga el tag Name.
# ─────────────────────────────────────────────────────────────────────────────
# data "aws_vpc" "selected" {
#   filter {
#     name   = "tag:Name"
#     values = [var.vpc_name]
#   }
# }

# ─────────────────────────────────────────────────────────────────────────────
# ESTRATEGIA 3 (alternativa): buscar VPC por combinación de tags
# Más precisa: garantiza que se elige la VPC del entorno correcto.
# ─────────────────────────────────────────────────────────────────────────────
# data "aws_vpc" "selected" {
#   tags = {
#     Name        = var.vpc_name
#     Environment = var.environment_name
#   }
# }

# ─────────────────────────────────────────────────────────────────────────────
# ESTRATEGIA 4 (alternativa): VPC por defecto de la cuenta
# ─────────────────────────────────────────────────────────────────────────────
# data "aws_vpc" "selected" {
#   default = true
# }

# ─────────────────────────────────────────────────────────────────────────────
# ESTRATEGIA 5: listar IDs de todas las VPCs que cumplan filtros de tags
# Devuelve una lista; útil para depuración o para iterar.
# ─────────────────────────────────────────────────────────────────────────────
data "aws_vpcs" "all" {}

data "aws_vpcs" "by_env_tag" {
  filter {
    name   = "tag:Environment"
    values = [var.environment_name]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# SUBREDES de la VPC elegida
# ─────────────────────────────────────────────────────────────────────────────

# Todas las subredes de la VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Subredes filtradas por zona de disponibilidad
data "aws_subnets" "by_az" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "availabilityZone"
    values = [var.availability_zone]
  }
}

# Subredes públicas (tienen auto-assign de IP pública)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Subred concreta: primera subred de la zona elegida
data "aws_subnet" "target" {
  id = data.aws_subnets.by_az.ids[0]
}

# ─────────────────────────────────────────────────────────────────────────────
# AMI Ubuntu más reciente
# aws ec2 describe-images --owners 099720109477 \
#   --filters 'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*' \
#   --output json --region eu-west-3
# ─────────────────────────────────────────────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
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
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}