provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = "10.208.0.0/20"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets      = ["10.208.1.0/24", "10.208.2.0/24", "10.208.3.0/24"]
  public_subnets       = ["10.208.4.0/24", "10.208.5.0/24", "10.208.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    "Owner"                                     = var.owner
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    "Owner"                                     = var.owner
  }
}

# Generate IAM Role and access to EKS
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "k8s_role_policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "k8s_role" {
  name = "${var.cluster_name}-access"
  assume_role_policy = data.aws_iam_policy_document.k8s_role_policy.json
}

data "aws_iam_policy_document" "k8s_assume_role" {
  statement {
    sid = ""

    actions = ["sts:AssumeRole"]

    resources = [resource.aws_iam_role.k8s_role.arn]
  }
}

resource "aws_iam_policy" "k8s_assume_role" {
  name        = "${var.cluster_name}-access-policy"
  path        = "/"
  description = "Policy to allow assuming role to access k8s cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.k8s_assume_role.json
}

resource "aws_iam_group" "k8s_access_group" {
  name = "${var.cluster_name}-users"
  path = "/"
}

resource "aws_iam_group_membership" "k8s_access_users" {
  name = "${var.cluster_name}-users"
  users = var.aws_users

  group = resource.aws_iam_group.k8s_access_group.name
}

resource "aws_iam_group_policy_attachment" "attach_k8s_access" {
  group      = resource.aws_iam_group.k8s_access_group.name
  policy_arn = resource.aws_iam_policy.k8s_assume_role.arn
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "16.0.1"

  cluster_name     = var.cluster_name
  cluster_version  = "1.21"
  subnets          = module.vpc.private_subnets
  write_kubeconfig = true
  vpc_id           = module.vpc.vpc_id
  enable_irsa      = true

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                 = "worker-group"
      instance_type        = "t2.small"
      asg_desired_capacity = 2
    }
  ]
  tags = {
    "Owner" = var.owner
  }

  map_roles = [
    {
      rolearn  = resource.aws_iam_role.k8s_role.arn
      username = "${var.cluster_name}-access"
      groups   = ["system:masters"]
    },
  ]

}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
