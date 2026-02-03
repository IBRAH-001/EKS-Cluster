output "endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

output "cluster_id" {
  value = aws_eks_cluster.eks.id
}

output "oidc_provider_arn" {
  value = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}