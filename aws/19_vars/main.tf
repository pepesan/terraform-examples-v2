############################
# VARIABLES
############################

variable "region" {
  description = "Región donde se desplegarán los recursos"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "Tipo de instancia de referencia, aunque no se creará ninguna EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Número teórico de instancias"
  type        = number
  default     = 1
}

variable "enable_monitoring" {
  description = "Activa o desactiva opciones de monitorización"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "Lista de CIDRs permitidos para SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "extra_security_group_ids" {
  description = "Conjunto de security groups adicionales"
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "terraform-demo"
    ManagedBy   = "terraform"
  }
}

variable "ssh_config" {
  description = "Configuración de claves SSH"
  type = object({
    public_key_path  = string
    private_key_path = string
  })
}

variable "deployment_info" {
  description = "Tupla con datos fijos del despliegue"
  type        = tuple([string, number, bool])
  default     = ["dev", 22, true]
}

variable "extra_config" {
  description = "Configuración libre adicional"
  type        = any
  default     = null
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "profe"
}

############################
# LOCALS
############################

locals {
  environment_name = var.deployment_info[0]
  ssh_port         = var.deployment_info[1]
  ssh_enabled      = var.deployment_info[2]

  merged_tags = merge(var.tags, {
    Name        = "terraform-${var.project_name}"
    Environment = local.environment_name
  })
}

############################
# PROVIDER
############################

provider "aws" {
  region = var.region
}


############################
# RECURSOS
############################

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-ubuntu-${var.project_name}"
  public_key = file(var.ssh_config.public_key_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh-${var.project_name}"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.merged_tags
}

############################
# OUTPUTS
############################

output "deployment_region" {
  description = "Región configurada"
  value       = var.region
}

output "instance_type_declared" {
  description = "Tipo de instancia declarado como variable"
  value       = var.instance_type
}

output "instance_count_declared" {
  description = "Número teórico de instancias"
  value       = var.instance_count
}

output "monitoring_enabled" {
  description = "Valor booleano de monitorización"
  value       = var.enable_monitoring
}

output "allowed_ssh_cidrs" {
  description = "CIDRs permitidos para SSH"
  value       = var.allowed_ssh_cidrs
}

output "extra_security_group_ids" {
  description = "Security groups extra"
  value       = var.extra_security_group_ids
}

output "tags_used" {
  description = "Tags aplicadas"
  value       = local.merged_tags
}

output "deployment_tuple_used" {
  description = "Tupla usada en el despliegue"
  value       = var.deployment_info
}

output "extra_config_value" {
  description = "Valor recibido en extra_config"
  value       = var.extra_config
}

output "security_group_id" {
  description = "ID del security group creado"
  value       = aws_security_group.allow_ssh.id
}

output "keypair_name" {
  description = "Nombre del key pair creado"
  value       = aws_key_pair.deployer.key_name
}