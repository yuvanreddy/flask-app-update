output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, "")
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = try(aws_iam_openid_connect_provider.cluster[0].arn, "")
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "The status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = try(aws_iam_role.alb_controller[0].arn, "")
}

output "alb_controller_service_account" {
  description = "Kubernetes service account name for AWS Load Balancer Controller"
  value       = "aws-load-balancer-controller"
}