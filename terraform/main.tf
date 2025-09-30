terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Optional: Use S3 backend for state management
  # Uncomment and configure after creating S3 bucket and DynamoDB table
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "eks-cluster/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  # IMPORTANT: Only use static values, no timestamp() or dynamic functions
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Get current AWS account information
data "aws_caller_identity" "current" {}

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module - Creates networking infrastructure
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# EKS Module - Creates Kubernetes cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # Cluster add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # EKS Managed Node Group defaults
  eks_managed_node_group_defaults = {
    instance_types = var.node_instance_types
    
    attach_cluster_primary_security_group = true
    
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    # Default on-demand node group
    default = {
      name = "ng-default"
      
      # Disable name prefix to avoid IAM role name length issues
      use_name_prefix          = false
      iam_role_name            = "${var.project_name}-ng-role"
      iam_role_use_name_prefix = false

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      disk_size = var.node_disk_size

      labels = {
        role        = "worker"
        environment = var.environment
      }

      tags = {
        Name        = "${var.cluster_name}-node"
        Environment = var.environment
      }
    }

    # Optional: Spot instances node group for cost optimization
    spot = {
      name = "ng-spot"
      
      # Disable name prefix to avoid IAM role name length issues
      use_name_prefix          = false
      iam_role_name            = "${var.project_name}-ng-spot-role"
      iam_role_use_name_prefix = false

      min_size     = var.spot_node_group_min_size
      max_size     = var.spot_node_group_max_size
      desired_size = var.spot_node_group_desired_size

      instance_types = var.spot_instance_types
      capacity_type  = "SPOT"

      disk_size = var.node_disk_size

      labels = {
        role        = "worker-spot"
        environment = var.environment
      }

      # Taints to prevent regular pods from scheduling on spot instances
      # Note: Must be a list, and effect must be uppercase with underscores
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]

      tags = {
        Name        = "${var.cluster_name}-spot-node"
        Environment = var.environment
      }
    }
  }

  # Cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

# Kubernetes Provider - Configure after EKS cluster is created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Create Kubernetes namespace for Flask application
resource "kubernetes_namespace" "flask_app" {
  metadata {
    name = "flask-app"
    
    labels = {
      name        = "flask-app"
      environment = var.environment
    }
  }

  depends_on = [module.eks]
}

# Create Cloudsmith registry secret for pulling Docker images
resource "kubernetes_secret" "cloudsmith_registry" {
  metadata {
    name      = "cloudsmith-registry"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "docker.cloudsmith.io" = {
          username = var.cloudsmith_username
          password = var.cloudsmith_api_key
          auth     = base64encode("${var.cloudsmith_username}:${var.cloudsmith_api_key}")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.flask_app]
}

# IAM role for AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-alb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name        = "${var.cluster_name}-alb-controller"
    Environment = var.environment
  }
}

# IAM role for EBS CSI Driver
module "ebs_csi_driver_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Name        = "${var.cluster_name}-ebs-csi"
    Environment = var.environment
  }
}

# Security group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-alb-sg"
    Environment = var.environment
  }
}