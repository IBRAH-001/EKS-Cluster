variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the EKS node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to launch nodes into"
  type        = list(string)
}

variable "instance_types" {
  description = "Instance types for the EKS node group"
  type        = list(string)
}

variable "ami_type" {
  description = "AMI type (e.g. AL2_x86_64, AL2_ARM_64)"
  type        = string
  default     = "AL2_ARM_64"
}

variable "capacity_type" {
  description = "Capacity type (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "enable_remote_access" {
  description = "Whether to enable SSH access to worker nodes"
  type        = bool
  default     = false
}

variable "ec2_ssh_key_name" {
  description = "SSH key name to use for accessing worker nodes"
  type        = string
  default     = ""
}

variable "security_group_id" {
  description = "Security group ID to allow SSH from"
  type        = string
  default     = ""
}

variable "node_security_group_ids" {
  description = "List of security group IDs to attach to the node instances"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Map of common tags"
  type        = map(string)
  default     = {}
}

variable "scaling_config" {
  description = "Auto-scaling configuration"
  type = object({
    min_size        = number
    desired_size    = number
    max_size        = number
    max_unavailable = number
  })
  default = {
    min_size        = 2
    desired_size    = 3
    max_size        = 5
    max_unavailable = 1
  }
}