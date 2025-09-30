# Terraform EKS Infrastructure

This directory contains Terraform configuration for provisioning an Amazon EKS cluster with all necessary infrastructure for the Flask application.

## Architecture

The Terraform configuration creates:

- **VPC**: With public and private subnets across 3 availability zones
- **EKS Cluster**: Managed Kubernetes cluster (version 1.28)
- **Node Groups**: 
  - Default: On-demand instances (t3.medium)
  - Spot: Optional spot instances for cost optimization
- **IAM Roles**: For cluster and service accounts (IRSA enabled)
- **Security Groups**: For cluster, nodes, and load balancers
- **Kubernetes Resources**: Namespaces and secrets
- **Add-ons**: CoreDNS, kube-proxy, VPC-CNI, EBS CSI Driver

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
   ```bash
   aws configure
   ```

2. **Terraform** installed (version 1.0+)
   ```bash
   # Windows (Chocolatey)
   choco install terraform
   
   # macOS (Homebrew)
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl** installed
   ```bash
   # Windows
   choco install kubernetes-cli
   
   # macOS
   brew install kubectl
   ```

## Quick Start

### 1. Configure Variables

Copy the example variables file and customize:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region   = "us-east-1"
cluster_name = "my-cluster"
environment  = "development"

# Update other variables as needed
```

### 2. Set Cloudsmith Credentials

```bash
# Option 1: Environment variables
export TF_VAR_cloudsmith_username="your-username"
export TF_VAR_cloudsmith_api_key="your-api-key"

# Option 2: Add to terraform.tfvars (not recommended for sensitive data)
# cloudsmith_username = "your-username"
# cloudsmith_api_key  = "your-api-key"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

This will take approximately 15-20 minutes.

### 6. Configure kubectl

```bash
aws eks update-kubeconfig --name flask-app-cluster --region us-east-1
kubectl get nodes
```

## Using Make Commands

A Makefile is provided for convenience:

```bash
# Initialize Terraform
make init

# Format code
make fmt

# Validate configuration
make validate

# Plan changes
make plan

# Apply changes
make apply

# Destroy infrastructure
make destroy

# Show outputs
make output

# Clean local files
make clean
```

## Cost Estimation

Estimated monthly costs (us-east-1):

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| EKS Cluster | 1 cluster | $73 |
| EC2 Instances | 3 x t3.medium | ~$90 |
| NAT Gateway | 1 gateway | ~$32 |
| Load Balancer | 1 ALB | ~$16 |
| EBS Volumes | 3 x 20GB | ~$6 |
| **Total** | | **~$217/month** |

**Cost Optimization Tips:**
- Use single NAT gateway instead of one per AZ
- Enable spot instances for non-critical workloads
- Use smaller instance types (t3.small) for dev/test
- Delete cluster when not in use

## Configuration Options

### Node Group Sizing

```hcl
# Development
node_group_min_size     = 1
node_group_max_size     = 3
node_group_desired_size = 2

# Production
node_group_min_size     = 3
node_group_max_size     = 10
node_group_desired_size = 5
```

### Enable Spot Instances

```hcl
enable_spot_instances        = true
spot_node_group_min_size     = 1
spot_node_group_max_size     = 5
spot_node_group_desired_size = 2
```

### High Availability

```hcl
# Use multiple NAT gateways (one per AZ)
single_nat_gateway = false

# Enable private cluster endpoint
cluster_endpoint_public_access  = false
cluster_endpoint_private_access = true
```

## State Management

### Local State (Default)

State is stored locally in `terraform.tfstate`. **Not recommended for teams.**

### Remote State with S3 (Recommended)

1. Create S3 bucket and DynamoDB table:

```bash
# Create S3 bucket
aws s3 mb s3://my-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

2. Uncomment backend configuration in `main.tf`:

```hcl
backend "s3" {
  bucket         = "my-terraform-state-bucket"
  key            = "eks-cluster/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

3. Migrate state:

```bash
terraform init -migrate-state
```

## Outputs

After applying, Terraform provides useful outputs:

```bash
# View all outputs
terraform output

# Specific output
terraform output cluster_endpoint
terraform output configure_kubectl

# Get kubeconfig for CI/CD
terraform output -raw kubeconfig | base64 -w 0
```

## GitHub Actions Integration

The Terraform workflow (`.github/workflows/terraform.yml`) automatically:

1. **On Pull Request**:
   - Validates Terraform code
   - Runs `terraform plan`
   - Comments plan on PR

2. **On Push to Main**:
   - Applies Terraform changes
   - Updates infrastructure

3. **Manual Trigger**:
   - Can run plan, apply, or destroy

### Required GitHub Secrets

Add these secrets in GitHub repository settings:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `CLOUDSMITH_USERNAME`
- `CLOUDSMITH_API_KEY`

## Troubleshooting

### Issue: Terraform state locked

```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: EKS cluster creation fails

```bash
# Check CloudWatch logs
aws logs tail /aws/eks/flask-app-cluster/cluster --follow

# Verify IAM permissions
aws sts get-caller-identity
```

### Issue: Can't connect to cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --name flask-app-cluster --region us-east-1

# Verify cluster is active
aws eks describe-cluster --name flask-app-cluster --query cluster.status
```

### Issue: Node group not launching

```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name flask-app-cluster \
  --nodegroup-name standard-workers

# View events
kubectl get events -A
```

## Maintenance

### Updating Kubernetes Version

1. Update `kubernetes_version` in `terraform.tfvars`:
   ```hcl
   kubernetes_version = "1.29"
   ```

2. Apply changes:
   ```bash
   terraform apply
   ```

3. Update node groups (they will be replaced):
   ```bash
   terraform apply
   ```

### Scaling Node Groups

```bash
# Update desired size
terraform apply -var="node_group_desired_size=5"

# Or modify terraform.tfvars and apply
```

### Backup and Recovery

```bash
# Backup state file
aws s3 cp s3://my-terraform-state-bucket/eks-cluster/terraform.tfstate \
  ./backup-$(date +%Y%m%d).tfstate

# Export cluster configuration
kubectl get all -A -o yaml > cluster-backup.yaml
```

## Cleanup

### Destroy Infrastructure

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with: yes
```

**Warning**: This will delete:
- EKS cluster
- All nodes
- VPC and subnets
- All data in persistent volumes

## Security Best Practices

1. **Enable encryption**: EBS volumes and secrets are encrypted by default
2. **Use IRSA**: IAM Roles for Service Accounts enabled
3. **Network isolation**: Private subnets for nodes
4. **Security groups**: Restrict access to necessary ports only
5. **Regular updates**: Keep Kubernetes version up to date
6. **Audit logging**: Enable CloudWatch logging for EKS

## Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

## Support

For issues:
1. Check Terraform output for error messages
2. Review AWS CloudWatch logs
3. Verify IAM permissions
4. Consult AWS EKS documentation
5. Open an issue in the repository