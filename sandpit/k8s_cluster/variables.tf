variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "cluster_name" {
  default = "sandpit-k8s"
}

variable "owner" {
  description = "Name of the owner of this resource"
  type        = string
}

variable "aws_users" {
  description = "List of users who should be added to the group with EKS access"
  type        = list(string)
}
