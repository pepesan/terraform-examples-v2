terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "~> 5.50.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2.4"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.2.1"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.13.1"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "~> 2.3.7"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.8.1"
    }

  }
  required_version = ">= 1.7.1"
}
