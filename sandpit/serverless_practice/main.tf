module "dns" {
  source             = "../../modules/dns_backend"
  url                = var.url
  owner              = var.owner
  cloudflare_zone_id = var.cloudflare_zone_id
  url_prefix         = "sandpit"
  aws_region         = "us-east-2"
}

module "serverless_practice_function" {
  source              = "../../modules/lambda"
  code_bucket_name    = var.code_bucket_name
  application_name    = "serverless-practice"
  application_version = "v1.0.0"
  lambda_name         = "serverless-practice"
  owner               = var.owner
  aws_region          = "us-east-2"
}