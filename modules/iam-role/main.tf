########################################
# Create IAM Instance Profile
########################################

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  count = var.create_ssm_role ? 1 : 0
  name  = "${aws_iam_role.ssm_role[0].name}_profile"
  role  = aws_iam_role.ssm_role[0].name
}

resource "aws_iam_instance_profile" "secrets_instance_profile" {
  count = var.create_backend_role ? 1 : 0
  name  = "${aws_iam_role.backend_role[0].name}_profile"
  role  = aws_iam_role.backend_role[0].name
}

resource "aws_iam_instance_profile" "backup_instance_profile" {
  count = var.create_backup_role ? 1 : 0
  name  = "${aws_iam_role.backup_role[0].name}_profile"
  role  = aws_iam_role.backup_role[0].name
}

########################################
# Session Manager Role
########################################

resource "aws_iam_role" "ssm_role" {
  count = var.create_ssm_role ? 1 : 0
  name  = "ssm_role_${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role" "backend_role" {
  count = var.create_backend_role ? 1 : 0
  name  = "backend_role_${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_iam_role" "backup_role" {
  count = var.create_backup_role ? 1 : 0
  name  = "backup_role_${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })
}

############################################
# Lambda Function Role for reporting account
###########################################

resource "aws_iam_role" "lambda_exec" {
  count              = var.create_lambda_exec_role ? 1 : 0
  name               = "lambda_exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

###############################################################
# Policy Attachments for reporting account Lambda execution role
###############################################################

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment" {
  count      = var.create_lambda_exec_role && length(var.policies_for_lambda_exec_role) > 0 ? length(var.policies_for_lambda_exec_role) : 0
  role       = aws_iam_role.lambda_exec[0].name
  policy_arn = var.policies_for_lambda_exec_role[count.index].policy_arn
}


########################################
# Create IAM Role in Production Account
########################################

resource "aws_iam_role" "production_role" {
  count = var.create_production_role ? 1 : 0
  name  = "production_role_${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::831286133761:role/lambda_exec"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
########################################
# Policy Attachment for Production Role
########################################

resource "aws_iam_role_policy_attachment" "production_policy_attachment" {
  count      = var.create_production_role && length(var.policies_for_production_role) > 0 ? length(var.policies_for_production_role) : 0
  role       = aws_iam_role.production_role[0].name
  policy_arn = var.policies_for_production_role[count.index].policy_arn
}



########################################
# Policy Attachment for Session Manager
########################################

resource "aws_iam_role_policy_attachment" "ssm_managed_policy_attachment" {
  count      = var.create_ssm_role ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "ec2_role_for_ssm_policy_attachment" {
  count      = var.create_ssm_role ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  count      = length(var.ssm_role_policies)
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = var.ssm_role_policies[count.index].policy_arn
}

resource "aws_iam_role_policy_attachment" "ec2_role_for_cloudwatch_agent_attachment" {
  count      = var.create_ssm_role ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "backend_ssm_managed_policy_attachment" {
  count      = var.create_backend_role ? 1 : 0
  role       = aws_iam_role.backend_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "backend_ec2_role_for_ssm_policy_attachment" {
  count      = var.create_backend_role ? 1 : 0
  role       = aws_iam_role.backend_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "backend_ec2_role_for_cloudwatch_agent_policy_attachment" {
  count      = var.create_backend_role ? 1 : 0
  role       = aws_iam_role.backend_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "backend_policy_attachment" {
  count      = length(var.policies_for_backend_role)
  role       = aws_iam_role.backend_role[0].name
  policy_arn = var.policies_for_backend_role[count.index].policy_arn
}

resource "aws_iam_role_policy_attachment" "backup_policy_attachment" {
  count      = length(var.backup_role_policies)
  role       = aws_iam_role.backup_role[0].name
  policy_arn = var.backup_role_policies[count.index].policy_arn
}

resource "aws_iam_role_policy_attachment" "backup_ec2_role_for_ssm_policy_attachment" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "backup_ec2_role_for_cloudwatch_agent_policy_attachment" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "backup_ssm_managed_policy_attachment" {
  count      = var.create_backup_role ? 1 : 0
  role       = aws_iam_role.backup_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


##########################################################
# IAM Role for VPC flowlogs destination to CloudWatch logs
##########################################################

resource "aws_iam_role" "vpc_flow_logs_role" {
  count = var.create_vpc_flow_logs_role ? 1 : 0
  name  = "vpcFlowLogsRole_${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  count      = length(var.policies_for_vpc_flow_logs_role)
  role       = aws_iam_role.vpc_flow_logs_role[0].name
  policy_arn = var.policies_for_vpc_flow_logs_role[count.index].policy_arn
}


####################################################################################
# create IAM role for eventbridge to invoke lambda for scheduled events vpc flow logs
####################################################################################

resource "aws_iam_role" "eventbridge_invoke_lambda" {
  name = "eventbridge_invoke_lambda_${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}


#######################################################################
# Eks Cluster IAM Roles
########################################################################

resource "aws_iam_role" "eks-role" {
  count = var.create_eks_role ? 1 : 0
  name  = "${var.cluster_name}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  count      = var.create_eks_role ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role[0].name
}

resource "aws_iam_role_policy_attachment" "eks-service-policy" {
  count      = var.create_eks_role ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-role[0].name
}

resource "aws_iam_role_policy_attachment" "eks-vpc-resource-controller-policy" {
  count      = var.create_eks_role ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-role[0].name
}



########################################
# EKS Cluster Role
########################################

resource "aws_iam_role" "eks_cluster_role" {
  count = var.create_eks_cluster_role ? 1 : 0
  name  = "eks_cluster_role_${var.eks_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

}

# Managed policy attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.create_eks_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  count      = var.create_eks_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count      = var.create_eks_cluster_role ? 1 : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# Additional custom policy attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_custom_policies" {
  count      = var.create_eks_cluster_role ? length(var.policies_for_eks_cluster_role) : 0
  role       = aws_iam_role.eks_cluster_role[0].name
  policy_arn = var.policies_for_eks_cluster_role[count.index]
}



########################################
# EKS Node Group Role
########################################

resource "aws_iam_role" "eks_node_role" {
  count = var.create_eks_node_role ? 1 : 0
  name  = "eks_node_role_${var.eks_cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Managed policy attachments for nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Additional ECR policy to ensure proper authentication
resource "aws_iam_role_policy" "eks_ecr_auth" {
  count = var.create_eks_node_role ? 1 : 0
  name  = "eks-ecr-auth-policy"
  role  = aws_iam_role.eks_node_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_ssm_managed_policy" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "eks_node_ssm_full_access" {
  count      = var.create_eks_node_role ? 1 : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}


# Additional custom policy attachments
resource "aws_iam_role_policy_attachment" "eks_node_custom_policies" {
  count      = var.create_eks_node_role ? length(var.policies_for_eks_node_role) : 0
  role       = aws_iam_role.eks_node_role[0].name
  policy_arn = var.policies_for_eks_node_role[count.index]
}