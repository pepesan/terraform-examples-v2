
resource "aws_s3_bucket" "b" {
  bucket = "${var.client_name}-${var.project_name}-backend-tfstate"
  /*
  lifecycle {
    prevent_destroy = true
  }
  */

  tags = {
    Name        = "My bucket"
    Environment = "${var.client_name}-${var.project_name}-Dev"
  }
}
/*
resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.b.id
  acl    = var.acl_value
}
*/
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.b.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.b.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
/*
resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.b.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
*/

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.b.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ya no es necesaria una tabla de dynamodb para disponer de un backend remoto en s3
#resource "aws_dynamodb_table" "terraform_locks" {
#  name         = "${var.project_name}-${var.client_name}-up-and-running-locks"
#  billing_mode = "PAY_PER_REQUEST"
#  hash_key     = "LockID"
#
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#}



