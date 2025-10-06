variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "ARN of the ALB controller IAM role"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "URL of the EKS OIDC issuer"
  type        = string
}