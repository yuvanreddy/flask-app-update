# VPC Module
module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  enable_irsa           = var.enable_irsa
  enable_alb_controller = var.enable_alb_controller

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [module.vpc]
}

# EKS Node Group Module
module "node_group" {
  source = "./modules/node-group"

  cluster_name = module.eks.cluster_name

  subnet_ids       = module.vpc.private_subnet_ids
  instance_types   = var.node_instance_types
  disk_size        = var.node_disk_size
  desired_capacity = var.desired_capacity
  min_capacity     = var.min_capacity
  max_capacity     = var.max_capacity

  enable_cluster_autoscaler = var.enable_cluster_autoscaler

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )

  depends_on = [module.eks]
}