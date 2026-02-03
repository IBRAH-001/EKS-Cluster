############################################

provider "aws" {
  region = var.region


  default_tags {
    tags = local.default_tags
  }
}

locals {
  default_tags = {
    Environment = "Staging"
    Type        = "Staging"
    ManagedBy   = "Terraform"
    owner       = "DevOps"
  }
}

terraform {
  required_version = ">= 1.2.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}


module "network" {
  source = "../modules/vpc"
  name   = var.name

  single_nat_gateway                   = true
  one_nat_gateway_per_az               = false
  enable_public_ipv6                   = false
  azs                                  = var.azs
  cidr                                 = var.cidr
  public_subnets                       = var.public_subnets
  private_subnets                      = var.private_subnets
  tags                                 = var.tags
  centralized_vpc_flow_logs_bucket_arn = var.centralized_vpc_flow_logs_bucket_arn
  create_cloudwatch_log_group          = false
  cloudwatch_log_group_arn             = ""
  vpc_flow_logs_role_arn               = ""
  max_aggregation_interval             = 60
  log_retention_days                   = 365


  enable_eks_support = true
  eks_cluster_name   = var.eks_cluster_name 


  eks_private_subnet_tags = {
    "karpenter.sh/discovery" = var.eks_cluster_name
  }

  eks_public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

module "eks_iam_roles" {
  source                  = "../modules/iam-role"
  create_eks_cluster_role = true
  create_eks_node_role    = true

  eks_cluster_name = var.eks_cluster_name
  env              = var.env

}


########################################
# Security Groups
########################################

module "security_groups" {
  source                        = "../modules/security-groups"
  vpc_id                        = module.network.vpc_id
  vpc_cidr                      = var.cidr
  backup_private_ip             = ""
  redis_private_ip              = ""
  reporting_cidr                = "var.reporting_peer_cidr"
  tags                          = var.tags
  create_lambda_sg              = false
  create_default_sg             = true
  create_alb_sg                 = false
  create_api_sg                 = false
  create_redis_sg               = false
  create_mqtt_sg                = false
  create_elephants_sg           = false
  create_nginx_sg               = false
  create_registration_server_sg = false
  create_ssh_sg                 = false
  create_backups_sg             = false
  create_vpn_sg                 = true
  create_opensearch_sg          = false
  create_backend_services_sg    = false
  create_jenkins_sg             = false
  create_ocg_sg                 = false
  create_openldap_sg            = false
  create_eks_cluster_sg         = true
  create_eks_nodes_sg           = true
}


module "eks" {

  source                  = "../modules/eks"
  eks_cluster_name        = var.eks_cluster_name
  cluster_version         = var.cluster_version
  cluster_role_arn        = module.eks_iam_roles.eks_cluster_role_arn
  subnet_ids              = module.network.private_subnet_ids
  security_group_id       = module.security_groups.eks_cluster_security_group_id
  endpoint_public_access  = true
  endpoint_private_access = true
  enable_encryption       = false
  enable_logging          = false

  public_access_cidrs       = ["70.53.18.212/32"] # add your IP here to have access to the EKS API
  kms_key_arn               = ""
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
  tags                      = var.tags
}


module "node_group" {
  source           = "../modules/node-groupe"
  eks_cluster_name = module.eks.cluster_id
  node_role_arn    = module.eks_iam_roles.eks_node_role_arn
  subnet_ids       = module.network.private_subnet_ids
  instance_types   = ["t4g.medium"]
  ami_type         = "AL2023_ARM_64_STANDARD"
  capacity_type    = "ON_DEMAND"
  environment      = "staging"
  tags             = var.tags

  scaling_config = {
    min_size        = 1
    desired_size    = 2
    max_size        = 6
    max_unavailable = 1
  }

  enable_remote_access = false 
  ec2_ssh_key_name     = ""   
  security_group_id    = ""   
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_region" "current" {}