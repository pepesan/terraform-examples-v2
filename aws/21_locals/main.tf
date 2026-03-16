provider "aws" {
  region = var.region
}

variable "region" {
  description = "Región donde se desplegarán los recursos"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  type    = string
  default = "demo-cdd"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_suffix" {
  description = "Sufijo para hacer único el nombre del bucket"
  type        = string
  default     = "curso-001"
}

locals {
  bucket_name = "${var.project_name}-${var.environment}-${var.bucket_suffix}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "example" {
  bucket = local.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name     = local.bucket_name
      FullName = "${local.bucket_name}-storage"
    }
  )
}

output "bucket_name" {
  value = local.bucket_name
}

output "bucket_info" {
  value = "Bucket ${local.bucket_name} creado para ${var.environment}"
}

output "project_environment" {
  value = "${var.project_name}-${var.environment}"
}