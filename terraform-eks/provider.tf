provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "flask-eks"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}