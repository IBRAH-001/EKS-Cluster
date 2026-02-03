variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "region" {
  type        = string
  description = "AWS region for resources"
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "Name prefix for VPC resources"
}

variable "cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDR blocks"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDR blocks"
}

variable "centralized_vpc_flow_logs_bucket_arn" {
  type        = string
  description = "ARN of S3 bucket for VPC flow logs"
  default     = ""
}

variable "env" {
  type        = string
  description = "Environment name (e.g., staging, production)"
  default     = "staging"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version to use for the EKS cluster"
  default     = "1.34"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EKS cluster and sub-resources"
}