resource "aws_eks_node_group" "eks_nodegroup" {
  cluster_name    = var.eks_cluster_name
  node_group_name = "${var.eks_cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_types
  ami_type        = var.ami_type
  capacity_type   = var.capacity_type

  scaling_config {
    min_size     = var.scaling_config.min_size
    desired_size = var.scaling_config.desired_size
    max_size     = var.scaling_config.max_size
  }

  update_config {
    max_unavailable = var.scaling_config.max_unavailable
  }

  dynamic "remote_access" {
    for_each = var.enable_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.ec2_ssh_key_name
      source_security_group_ids = [var.security_group_id]
    }
  }

  labels = {
    "role"        = "worker-node"
    "env"         = var.environment
    "team"        = "platform"
    "instance"    = join(",", var.instance_types)
  }

  tags = merge({
    Name        = "${var.eks_cluster_name}-worker-nodes"
    Environment = var.environment
    Role        = "worker-node"
    ManagedBy   = "Terraform"
  }, var.tags)
}