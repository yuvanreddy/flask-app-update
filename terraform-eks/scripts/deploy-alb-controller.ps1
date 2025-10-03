# PowerShell script to deploy AWS Load Balancer Controller to EKS cluster
# Run this after EKS cluster is created

Write-Host "Deploying AWS Load Balancer Controller..." -ForegroundColor Cyan

# Navigate to terraform directory
cd terraform-eks

# Get cluster information from Terraform outputs
$CLUSTER_NAME = terraform output -raw cluster_name
$AWS_REGION = terraform output -raw region
$ALB_CONTROLLER_ROLE_ARN = terraform output -raw alb_controller_role_arn

if ([string]::IsNullOrEmpty($ALB_CONTROLLER_ROLE_ARN)) {
    Write-Host "Error: ALB Controller Role ARN not found" -ForegroundColor Red
    exit 1
}

Write-Host "Cluster Name: $CLUSTER_NAME" -ForegroundColor Green
Write-Host "Region: $AWS_REGION" -ForegroundColor Green
Write-Host "ALB Controller Role ARN: $ALB_CONTROLLER_ROLE_ARN" -ForegroundColor Green

# Configure kubectl
Write-Host "`nConfiguring kubectl..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Install AWS Load Balancer Controller CRDs
Write-Host "`nInstalling AWS Load Balancer Controller CRDs..." -ForegroundColor Yellow
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Read the template and replace placeholders
Write-Host "`nDeploying AWS Load Balancer Controller..." -ForegroundColor Yellow
$manifest = Get-Content -Path "..\kubernetes\aws-load-balancer-controller.yaml" -Raw
$manifest = $manifest -replace '\$\{CLUSTER_NAME\}', $CLUSTER_NAME
$manifest = $manifest -replace '\$\{AWS_REGION\}', $AWS_REGION
$manifest = $manifest -replace '\$\{ALB_CONTROLLER_ROLE_ARN\}', $ALB_CONTROLLER_ROLE_ARN

# Apply the manifest
$manifest | kubectl apply -f -

# Wait for deployment to be ready
Write-Host "`nWaiting for AWS Load Balancer Controller to be ready..." -ForegroundColor Yellow
kubectl wait --namespace kube-system `
    --for=condition=ready pod `
    --selector=app.kubernetes.io/name=aws-load-balancer-controller `
    --timeout=300s

Write-Host "`nAWS Load Balancer Controller deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Verify deployment:" -ForegroundColor Cyan
Write-Host "kubectl get deployment -n kube-system aws-load-balancer-controller"
Write-Host "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"