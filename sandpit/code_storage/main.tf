module "bucket" {
  source      = "../../modules/bucket"
  owner       = var.owner
  bucket_name = var.code_bucket_name
  aws_region  = "us-east-2"
}