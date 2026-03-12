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
    ec2 = "http://localhost.localstack.cloud:4566"
    iam = "http://localhost.localstack.cloud:4566"
    sts = "http://localhost.localstack.cloud:4566"
  }
}