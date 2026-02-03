variable "create_ssm_role" {
  description = "Whether to create the SSM role"
  type        = bool
  default     = false
}

variable "OU" {
  description = "OU account Number"
  default     = ""
  type        = string
}

variable "create_backend_role" {
  description = "Whether to create the Secrets Manager role"
  type        = bool
  default     = false
}

variable "create_backup_role" {
  description = "Whether to create the Backup role"
  type        = bool
  default     = false
}

variable "backup_role_policy" {
  description = "Policy for the backup role"
  type        = string
  default     = ""
}

variable "policies_for_backend_role" {
  description = "Policies required for backend services"
  type = list(object({
    policy_arn = string
  }))
  default = []
}

variable "backup_role_policies" {
  description = "Policies required for backup services"
  type = list(object({
    policy_arn = string
  }))
  default = []
}

variable "ssm_role_policies" {
  description = "Policies required for backup services"
  type = list(object({
    policy_arn = string
  }))
  default = []
}

variable "create_lambda_basic_execution" {
  description = "Whether to attach the AWSLambdaBasicExecutionRole policy"
  type        = bool
  default     = false
}

variable "create_ec2_full_access" {
  description = "Whether to attach the AmazonEC2FullAccess policy"
  type        = bool
  default     = false
}

variable "create_eventbridge_full_access" {
  description = "Whether to attach the AmazonEventBridgeFullAccess policy"
  type        = bool
  default     = false
}

variable "create_lambda_exec_role" {
  description = "Flag to indicate if the Lambda execution role should be created"
  type        = bool
  default     = false
}

variable "create_production_role" {
  description = "Flag to indicate if the production role should be created"
  type        = bool
  default     = false
}

variable "policies_for_production_role" {
  description = "Policies required for the production role"
  type = list(object({
    policy_arn = string
  }))
  default = []
}

variable "policies_for_lambda_exec_role" {
  description = "Policies required for the Lambda execution role"
  type = list(object({
    policy_arn = string
  }))
  default = []
}

variable "env" {
	description = "Environment"
	type        = string
}
variable "create_vpc_flow_logs_role" {
  description = "Whether to create the VPC Flow Logs role"
  type        = bool
  default     = false
  
}

variable "policies_for_vpc_flow_logs_role" {
  description = "Policies required for the production role"
  type = list(object({
    policy_arn = string
  }))
  default = []
}

variable "create_eks_role" {
  description = "Whether to create the EKS IAM role and its policy attachments"
  type        = bool
  default     = false
}


variable "cluster_name" { 
  description = "Name of the EKS cluster for which the IAM role is created"
  type        = string
  default     = ""
  
}


########################################
# EKS Cluster Role variables 
########################################

variable "create_eks_cluster_role" {
  description = "Whether to create IAM role for EKS cluster"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster (used in role naming)"
  type        = string
  default     = ""
}

variable "policies_for_eks_cluster_role" {
  description = "List of additional policy ARNs to attach to EKS cluster role"
  type        = list(string)
  default     = []
}


########################################
# EKS Cluster Node group Role variables 
########################################

variable "create_eks_node_role" {
  description = "Whether to create IAM role for EKS node groups"
  type        = bool
  default     = false
}

variable "policies_for_eks_node_role" {
  description = "List of additional policy ARNs to attach to EKS node role"
  type        = list(string)
  default     = []
}