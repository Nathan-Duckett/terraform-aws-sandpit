variable "url" {
  type = string
}

variable "url_prefix" {
  type    = string
  default = "sandbox"
}

variable "owner" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "aws_region" {
  type = string
}