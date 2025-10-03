output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.main.status
}

output "node_role_arn" {
  description = "ARN of the IAM role for nodes"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the IAM role for nodes"
  value       = aws_iam_role.node.name
}