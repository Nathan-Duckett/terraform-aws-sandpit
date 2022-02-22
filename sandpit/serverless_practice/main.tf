module "dns" {
  source             = "../../modules/dns_backend"
  url                = var.url
  owner              = var.owner
  cloudflare_zone_id = var.cloudflare_zone_id
  url_prefix         = "sandpit"
  aws_region         = "us-east-2"
}