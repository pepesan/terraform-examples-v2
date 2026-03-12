terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    s3  = "http://s3.localhost.localstack.cloud:4566"
    sts = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "bucket2"
}

output "bucket_name" {
  description = "Nombre del bucket creado"
  value       = aws_s3_bucket.bucket2.bucket
}

output "bucket_arn" {
  description = "ARN del bucket"
  value       = aws_s3_bucket.bucket2.arn
}