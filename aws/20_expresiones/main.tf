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

resource "aws_s3_bucket" "example" {
  bucket = "${var.project_name}-${var.environment}-bucket"

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
    FullName    = "${var.project_name}-${var.environment}-storage"
  }
}

output "bucket_name" {
  value = "${var.project_name}-${var.environment}-bucket"
}

output "bucket_info" {
  value = "Bucket ${aws_s3_bucket.example.bucket} creado para ${var.environment}"
}

output "project_environment" {
  value = "${var.project_name}-${var.environment}"
}