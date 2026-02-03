region          = "us-east-1"
name            = "eks-cluster-staging"
cidr            = "10.20.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets  = ["10.20.24.0/24", "10.20.25.0/24", "10.20.26.0/24"]
private_subnets = ["10.20.27.0/24", "10.20.28.0/24", "10.20.29.0/24"]
tags = {
  "Environment" = "Staging"
  "Type"        = "Staging"
}

eks_cluster_name = "stage-eks-cluster"
cluster_version  = "1.34"
