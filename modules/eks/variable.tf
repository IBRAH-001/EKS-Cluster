variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version to use for the EKS cluster"
  default     = "1.34"
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS control plane"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for EKS control plane (public or private)"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for EKS control plane networking"
}

variable "endpoint_public_access" {
  type        = bool
  description = "Enable or disable public endpoint access"
  default     = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Enable or disable private endpoint access"
  default     = true
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to access the public endpoint"
  default     = ["0.0.0.0/0"]
}

variable "kms_key_arn" {
  type        = string
  description = "KMS Key ARN for encrypting Kubernetes secrets"
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "EKS control plane logs to send to CloudWatch"
  default     = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to EKS cluster and sub-resources"
}

variable "enable_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Enable cluster control plane logging"
  type        = bool
  default     = false
}
