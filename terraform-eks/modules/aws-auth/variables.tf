variable "github_deployer_role_arn" {
  description = "ARN of the GitHub Actions deployer role"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  type        = string
}