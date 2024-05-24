provider "aws" {
  region = "eu-west-3"
}
variable "bucket_prefix" {
  type = string
}
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_prefix}-bucket"
}
output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
