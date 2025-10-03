# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.instance_types
  disk_size      = var.disk_size

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "worker"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.tags,
    var.enable_cluster_autoscaler ? {
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    } : {}
  )

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Launch Template (optional, for advanced configuration)
resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-lt"
  description = "Launch template for EKS nodes"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.cluster_name}-node"
      }
    )
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = var.cluster_name
  }))

  tags = var.tags
}