# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# EKS Cluster Outputs
output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

# Node Group Outputs
output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

# IAM Role Outputs
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa_role.iam_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of IAM role for EBS CSI Driver"
  value       = module.ebs_csi_driver_irsa_role.iam_role_arn
}

# ALB Security Group Output
output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

# Region Output
output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# Kubeconfig Output
output "kubeconfig" {
  description = "kubectl config file contents for this EKS cluster"
  value       = local_file.kubeconfig.content
  sensitive   = true
}

# Configure kubectl command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}