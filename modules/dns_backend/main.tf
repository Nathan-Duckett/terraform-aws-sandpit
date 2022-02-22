terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create Route 53 Zone
resource "aws_route53_zone" "cloudflare_connect" {
  name = "${var.url_prefix}.${var.url}"

  tags = {
    Owner = var.owner
  }
}

# Create Cloudflare records for Route 53 namespaces
resource "cloudflare_record" "ns_records" {
  count = 4

  zone_id = var.cloudflare_zone_id
  name    = var.url_prefix
  value   = aws_route53_zone.cloudflare_connect.name_servers[count.index]
  type    = "NS"
  ttl     = 3600
}