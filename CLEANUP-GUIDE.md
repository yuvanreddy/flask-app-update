# Infrastructure Cleanup Guide

**Cluster:** flask-eks  
**Date:** October 9, 2025  
**Purpose:** Safely stop deployments and destroy infrastructure

---

## ⚠️ Warning

This will:
- Delete all running applications
- Remove monitoring stack
- Destroy EKS cluster
- Delete all AWS resources (VPC, Load Balancers, EBS volumes)
- **Data will be lost** (photos, database)

---

## 📋 Cleanup Order

### **Phase 1: Stop Application Deployments**
### **Phase 2: Remove Monitoring Stack**
### **Phase 3: Destroy EKS Infrastructure**
### **Phase 4: Verify Cleanup**

---

## 🛑 Phase 1: Stop Application Deployments

### **Step 1: Scale Down Flask App**
```powershell
# Scale to 0 replicas
kubectl scale deployment flask-app -n default --replicas=0

# Verify
kubectl get pods -n default
```

### **Step 2: Delete Flask App Resources**
```powershell
# Delete deployment
kubectl delete deployment flask-app -n default

# Delete service
kubectl delete service flask-svc -n default

# Delete ingress
kubectl delete ingress flask-alb -n default

# Delete PVCs (this will delete EBS volumes and data)
kubectl delete pvc flask-app-uploads-pvc -n default
kubectl delete pvc flask-app-thumbnails-pvc -n default
kubectl delete pvc flask-app-db-pvc -n default

# Delete secrets
kubectl delete secret cloudsmith-regcred -n default

# Delete service account
kubectl delete serviceaccount flask-app-sa -n default
```

---

## 📊 Phase 2: Remove Monitoring Stack

### **Step 1: Uninstall Prometheus Stack**
```powershell
# Uninstall Helm release
helm uninstall prometheus-stack -n monitoring

# Wait for resources to be deleted
Start-Sleep -Seconds 30
```

### **Step 2: Delete Monitoring Namespace**
```powershell
# Delete namespace (this removes all monitoring resources)
kubectl delete namespace monitoring

# This will delete:
# - Prometheus
# - Grafana
# - Alertmanager
# - All PVCs and data
```

---

## 🔥 Phase 3: Destroy EKS Infrastructure

### **Step 1: Prepare for Terraform Destroy**
```powershell
# Navigate to terraform directory
cd terraform-eks
```

### **Step 2: Run Terraform Destroy**
```powershell
# Initialize Terraform (if needed)
terraform init

# Review what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy -auto-approve
```

**This will delete:**
- EKS Cluster
- Worker Nodes
- VPC and Subnets
- NAT Gateways
- Internet Gateway
- Security Groups
- IAM Roles
- Load Balancers
- EBS Volumes
- All associated AWS resources

**Duration:** 15-20 minutes

---

## ✅ Phase 4: Verify Cleanup

### **Step 1: Verify Kubernetes Resources Deleted**
```powershell
# Try to connect to cluster (should fail)
kubectl get nodes

# Expected: Error - cluster not found
```

### **Step 2: Verify AWS Resources Deleted**
```powershell
# Check EKS clusters
aws eks list-clusters --region us-east-1

# Check Load Balancers
aws elbv2 describe-load-balancers --region us-east-1 | Select-String flask

# Check VPCs
aws ec2 describe-vpcs --region us-east-1 --filters "Name=tag:Name,Values=flask-eks-vpc"

# Check EBS volumes
aws ec2 describe-volumes --region us-east-1 --filters "Name=tag:kubernetes.io/cluster/flask-eks,Values=owned"
```

### **Step 3: Check for Remaining Resources**
```powershell
# Check S3 buckets (Terraform state)
aws s3 ls | Select-String terraform

# Check CloudWatch log groups
aws logs describe-log-groups --region us-east-1 | Select-String flask-eks
```

---

## 🧹 Optional: Clean Up Additional Resources

### **Delete Terraform State (Optional)**
```powershell
# If you want to remove Terraform state from S3
aws s3 rm s3://terraform-state-816069153839/eks/terraform.tfstate

# Delete state bucket (if no longer needed)
aws s3 rb s3://terraform-state-816069153839 --force
```

### **Delete CloudWatch Logs (Optional)**
```powershell
# Delete EKS cluster logs
aws logs delete-log-group --log-group-name /aws/eks/flask-eks/cluster --region us-east-1
```

### **Delete OIDC Provider (Optional)**
```powershell
# List OIDC providers
aws iam list-open-id-connect-providers

# Delete if needed
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::816069153839:oidc-provider/token.actions.githubusercontent.com
```

---

## 💰 Cost Savings

After cleanup, you will stop incurring costs for:
- ✅ EKS Cluster: ~$73/month
- ✅ EC2 Instances (t3.medium x2): ~$60/month
- ✅ NAT Gateways (x3): ~$100/month
- ✅ Load Balancers: ~$20/month
- ✅ EBS Volumes: ~$2/month
- ✅ Data Transfer: Variable

**Total Savings: ~$255/month**

---

## 🔄 To Recreate Infrastructure Later

### **Step 1: Run Terraform Apply**
```powershell
cd terraform-eks
terraform init
terraform apply -auto-approve
```

### **Step 2: Deploy Application**
```powershell
# Update kubeconfig
aws eks update-kubeconfig --name flask-eks --region us-east-1

# Apply Kubernetes manifests
kubectl apply -f k8s/
```

### **Step 3: Reinstall Monitoring**
```powershell
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/prometheus-values.yaml
```

---

## 📊 Cleanup Checklist

**Before Cleanup:**
- [ ] Backup any important data
- [ ] Export Grafana dashboards
- [ ] Save any custom configurations
- [ ] Notify team members

**During Cleanup:**
- [ ] Scale down deployments
- [ ] Delete Kubernetes resources
- [ ] Uninstall Helm releases
- [ ] Run Terraform destroy
- [ ] Wait for completion

**After Cleanup:**
- [ ] Verify cluster deleted
- [ ] Check AWS console for remaining resources
- [ ] Verify no unexpected charges
- [ ] Update documentation

---

## ⏱️ Estimated Time

- Phase 1 (Stop Deployments): 2-3 minutes
- Phase 2 (Remove Monitoring): 3-5 minutes
- Phase 3 (Destroy Infrastructure): 15-20 minutes
- Phase 4 (Verification): 2-3 minutes

**Total: ~25-30 minutes**

---

## 🆘 Troubleshooting

### **Issue: Terraform Destroy Hangs**

**Cause:** Resources still in use (Load Balancers, Security Groups)

**Solution:**
```powershell
# Manually delete Load Balancers
aws elbv2 describe-load-balancers --region us-east-1 | Select-String flask
aws elbv2 delete-load-balancer --load-balancer-arn <ARN>

# Wait and retry
terraform destroy -auto-approve
```

### **Issue: PVCs Not Deleting**

**Cause:** Finalizers preventing deletion

**Solution:**
```powershell
# Remove finalizers
kubectl patch pvc flask-app-uploads-pvc -n default -p '{"metadata":{"finalizers":null}}'
kubectl patch pvc flask-app-thumbnails-pvc -n default -p '{"metadata":{"finalizers":null}}'
kubectl patch pvc flask-app-db-pvc -n default -p '{"metadata":{"finalizers":null}}'
```

### **Issue: Namespace Stuck in Terminating**

**Cause:** Resources with finalizers

**Solution:**
```powershell
# Force delete namespace
kubectl get namespace monitoring -o json | ConvertTo-Json | Set-Content temp.json
# Edit temp.json and remove finalizers
kubectl replace --raw "/api/v1/namespaces/monitoring/finalize" -f temp.json
```

---

**Created:** October 9, 2025  
**Status:** Ready to execute
