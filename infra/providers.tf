terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # S3 backend for state management
  backend "s3" {
    bucket         = "capstone-terraform-state-710504359366"
    key            = "envs/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "capstone-terraform-locks-710504359366"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
