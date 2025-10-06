output "github_deployer_role_arn" {
  description = "ARN of the GitHub Actions deployer role"
  value       = aws_iam_role.github_deployer.arn
}

output "alb_controller_role_arn" {
  description = "ARN of the ALB controller role"
  value       = aws_iam_role.alb_controller.arn
}