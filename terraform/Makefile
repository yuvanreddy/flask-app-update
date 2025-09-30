.PHONY: help init fmt validate plan apply destroy output clean check-aws

# Default target
help:
	@echo "Terraform EKS Infrastructure Management"
	@echo ""
	@echo "Available targets:"
	@echo "  init       - Initialize Terraform"
	@echo "  fmt        - Format Terraform files"
	@echo "  validate   - Validate Terraform configuration"
	@echo "  plan       - Show Terraform execution plan"
	@echo "  apply      - Apply Terraform changes"
	@echo "  destroy    - Destroy Terraform-managed infrastructure"
	@echo "  output     - Show Terraform outputs"
	@echo "  clean      - Clean local Terraform files"
	@echo "  check-aws  - Verify AWS credentials"
	@echo "  kubeconfig - Update kubectl configuration"
	@echo "  show-cost  - Estimate infrastructure costs"
	@echo ""

# Check AWS credentials
check-aws:
	@echo "Checking AWS credentials..."
	@aws sts get-caller-identity
	@echo "✓ AWS credentials configured"

# Initialize Terraform
init: check-aws
	@echo "Initializing Terraform..."
	terraform init

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Validate Terraform configuration
validate: init
	@echo "Validating Terraform configuration..."
	terraform validate

# Plan Terraform changes
plan: validate
	@echo "Creating Terraform plan..."
	terraform plan -out=tfplan

# Apply Terraform changes
apply: plan
	@echo "Applying Terraform changes..."
	terraform apply tfplan
	@rm -f tfplan

# Quick apply without plan (use with caution)
quick-apply: validate
	@echo "Applying Terraform changes without plan..."
	terraform apply -auto-approve

# Destroy infrastructure
destroy: check-aws
	@echo "⚠️  WARNING: This will destroy all infrastructure!"
	@echo "Press Ctrl+C to cancel or Enter to continue..."
	@read
	terraform destroy

# Show outputs
output:
	@terraform output

# Get specific output
output-%:
	@terraform output -raw $*

# Update kubectl configuration
kubeconfig:
	@echo "Updating kubectl configuration..."
	@eval $$(terraform output -raw configure_kubectl)
	@kubectl get nodes

# Show cost estimation
show-cost:
	@echo "Estimated monthly costs:"
	@echo "  EKS Cluster:     $$73"
	@echo "  EC2 (3x t3.med): ~$$90"
	@echo "  NAT Gateway:     ~$$32"
	@echo "  Load Balancer:   ~$$16"
	@echo "  EBS Volumes:     ~$$6"
	@echo "  ─────────────────────"
	@echo "  Total:           ~$$217/month"

# Clean local files
clean:
	@echo "Cleaning local Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f tfplan
	rm -f terraform.tfstate.backup

# Refresh state
refresh:
	@echo "Refreshing Terraform state..."
	terraform refresh

# Show state
show:
	@terraform show

# Import existing resource
import:
	@echo "Example: make import-resource RESOURCE=aws_instance.example ID=i-1234567890abcdef0"

import-resource:
	terraform import $(RESOURCE) $(ID)

# Taint resource
taint:
	@echo "Example: make taint-resource RESOURCE=module.eks.aws_eks_node_group.default"

taint-resource:
	terraform taint $(RESOURCE)

# Untaint resource
untaint:
	@echo "Example: make untaint-resource RESOURCE=module.eks.aws_eks_node_group.default"

untaint-resource:
	terraform untaint $(RESOURCE)

# Show resource graph
graph:
	@echo "Generating resource graph..."
	terraform graph | dot -Tpng > graph.png
	@echo "Graph saved to graph.png"

# Workspace management
workspace-list:
	@terraform workspace list

workspace-new:
	@echo "Example: make workspace-new NAME=staging"
	terraform workspace new $(NAME)

workspace-select:
	@echo "Example: make workspace-select NAME=staging"
	terraform workspace select $(NAME)

# Lock management
unlock:
	@echo "Example: make unlock LOCK_ID=abc123"
	terraform force-unlock $(LOCK_ID)

# State management
state-list:
	@terraform state list

state-show:
	@echo "Example: make state-show RESOURCE=module.eks.aws_eks_cluster.this[0]"
	terraform state show $(RESOURCE)

state-mv:
	@echo "Example: make state-mv SOURCE=old.resource DEST=new.resource"
	terraform state mv $(SOURCE) $(DEST)

state-rm:
	@echo "Example: make state-rm RESOURCE=module.eks.aws_eks_node_group.spot[0]"
	terraform state rm $(RESOURCE)

state-pull:
	@terraform state pull > terraform.tfstate.backup

state-push:
	@terraform state push terraform.tfstate.backup

# Security scanning
security-scan:
	@echo "Running security scans..."
	@command -v tfsec >/dev/null 2>&1 && tfsec . || echo "tfsec not installed"
	@command -v checkov >/dev/null 2>&1 && checkov -d . || echo "checkov not installed"

# Generate documentation
docs:
	@command -v terraform-docs >/dev/null 2>&1 && terraform-docs markdown table . > TERRAFORM_DOCS.md || echo "terraform-docs not installed"

# Full workflow
full-deploy: fmt validate plan apply kubeconfig
	@echo "✓ Full deployment complete!"

# Full cleanup
full-cleanup: destroy clean
	@echo "✓ Full cleanup complete!"