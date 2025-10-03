#!/bin/bash
set -e

# Script to deploy AWS Load Balancer Controller to EKS cluster
# Run this after EKS cluster is created

echo "Deploying AWS Load Balancer Controller..."

# Get cluster information from Terraform outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw region)
ALB_CONTROLLER_ROLE_ARN=$(terraform output -raw alb_controller_role_arn)

if [ -z "$ALB_CONTROLLER_ROLE_ARN" ]; then
    echo "Error: ALB Controller Role ARN not found"
    exit 1
fi

echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "ALB Controller Role ARN: $ALB_CONTROLLER_ROLE_ARN"

# Configure kubectl
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Apply CRDs for AWS Load Balancer Controller
echo "Installing AWS Load Balancer Controller CRDs..."
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Replace placeholders in the manifest
sed -e "s|\${CLUSTER_NAME}|$CLUSTER_NAME|g" \
    -e "s|\${AWS_REGION}|$AWS_REGION|g" \
    -e "s|\${ALB_CONTROLLER_ROLE_ARN}|$ALB_CONTROLLER_ROLE_ARN|g" \
    ../kubernetes/aws-load-balancer-controller.yaml | kubectl apply -f -

echo "Waiting for AWS Load Balancer Controller to be ready..."
kubectl wait --namespace kube-system \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/name=aws-load-balancer-controller \
    --timeout=300s

echo "AWS Load Balancer Controller deployed successfully"
echo ""
echo "Verify deployment:"
echo "kubectl get deployment -n kube-system aws-load-balancer-controller"
echo "kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"