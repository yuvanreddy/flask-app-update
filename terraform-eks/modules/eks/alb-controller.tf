# IAM Policy for AWS Load Balancer Controller
data "http" "alb_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  name        = "${var.cluster_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_controller_iam_policy.response_body

  tags = var.tags
}

# IAM Role for AWS Load Balancer Controller using IRSA
resource "aws_iam_role" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  name = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : ""
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  policy_arn = aws_iam_policy.alb_controller[0].arn
  role       = aws_iam_role.alb_controller[0].name
}