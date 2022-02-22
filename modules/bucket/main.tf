terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = var.bucket_name

  tags = {
    Owner = var.owner
  }
}