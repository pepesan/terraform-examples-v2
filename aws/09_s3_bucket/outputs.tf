output "s3_bucket_arn" {
  value       = aws_s3_bucket.b.arn
  description = "The ARN of the S3 bucket"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.b.bucket_domain_name
  description = "The Domain name of the S3 bucket"
}

# ya no es necesaria una tabla de dynamodb para disponer de un backend remoto en s3
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}
