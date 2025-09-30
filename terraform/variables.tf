variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "flask-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "development"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "flask-app-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to cluster endpoint"
  type        = bool
  default     = true
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = true
}

# Node Group Variables
variable "node_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type for nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the default node group"
  type        = number
  default     = 5
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 3
}

# Spot Instance Variables
variable "spot_instance_types" {
  description = "List of instance types for spot instances"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "spot_node_group_min_size" {
  description = "Minimum number of spot nodes"
  type        = number
  default     = 0
}

variable "spot_node_group_max_size" {
  description = "Maximum number of spot nodes"
  type        = number
  default     = 3
}

variable "spot_node_group_desired_size" {
  description = "Desired number of spot nodes"
  type        = number
  default     = 0
}

# Cloudsmith Variables
variable "cloudsmith_username" {
  description = "Cloudsmith username for Docker registry"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudsmith_api_key" {
  description = "Cloudsmith API key for Docker registry"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_spot_instances" {
  description = "Enable spot instance node group"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}