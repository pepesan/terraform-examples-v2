terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "~> 5.50.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2.2"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.11.1"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "~> 2.3.4"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.2"
    }

  }
  required_version = ">= 1.7.1"
}
