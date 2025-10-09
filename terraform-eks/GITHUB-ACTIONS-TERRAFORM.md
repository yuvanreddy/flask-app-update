# GitHub Actions - Terraform Infrastructure Management

**Workflow File:** `.github/workflows/terraform-infrastructure.yml`  
**Purpose:** Automated Terraform apply and destroy operations  
**Date:** October 9, 2025

---

## 🚀 Features

### **Terraform Operations:**
- ✅ **Plan** - Preview infrastructure changes
- ✅ **Apply** - Create/update infrastructure
- ✅ **Destroy** - Delete all infrastructure
- ✅ Auto-approve option for automation

### **Information Display:**
- ✅ EKS cluster details (name, version, endpoint)
- ✅ Worker node count
- ✅ VPC ID and networking info
- ✅ Access commands (kubeconfig update)
- ✅ Cost estimates
- ✅ Next steps guidance

### **Verification:**
- ✅ Post-deployment health checks
- ✅ Addon verification
- ✅ Load Balancer Controller check
- ✅ Node status validation

---

## 📋 Prerequisites

### **1. AWS Credentials**
Ensure `AWS_ROLE_TO_ASSUME` secret is configured:
```
Settings → Secrets and variables → Actions → New repository secret
Name: AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::816069153839:role/github-deployer-role
```

### **2. Terraform State Backend**
S3 bucket for Terraform state:
```
Bucket: terraform-state-816069153839
Key: eks/terraform.tfstate
Region: us-east-1
```

### **3. Required Files**
- `terraform-eks/*.tf` files
- `terraform-eks/terraform.tfvars`

---

## 🎯 How to Use

### **Method 1: Plan (Preview Changes)**

1. **Go to GitHub Actions:**
   ```
   Your Repository → Actions → Terraform Infrastructure Management
   ```

2. **Click "Run workflow"**

3. **Select action:** `plan`

4. **Click "Run workflow"**

5. **Review the plan** in workflow output

### **Method 2: Apply (Create Infrastructure)**

1. **Go to GitHub Actions**

2. **Click "Run workflow"**

3. **Select action:** `apply`

4. **Auto-approve:**
   - ✅ Check for automatic approval
   - ⬜ Uncheck to require manual confirmation

5. **Click "Run workflow"**

6. **Wait 15-20 minutes** for completion

7. **Check Summary tab** for cluster URLs and access info

### **Method 3: Destroy (Delete Infrastructure)**

1. **Go to GitHub Actions**

2. **Click "Run workflow"**

3. **Select action:** `destroy`

4. **Auto-approve:**
   - ✅ Check for automatic approval (⚠️ dangerous!)
   - ⬜ Uncheck for safety

5. **Click "Run workflow"**

6. **Wait 15-20 minutes** for completion

---

## 📊 Workflow Output

### **After Successful Apply:**

```
╔════════════════════════════════════════════════════════════════╗
║        INFRASTRUCTURE DEPLOYMENT SUCCESSFUL! 🎉                ║
╚════════════════════════════════════════════════════════════════╝

🌐 EKS CLUSTER INFORMATION:
┌────────────────────────────────────────────────────────────────┐
│ Cluster Name:    flask-eks
│ Region:          us-east-1
│ Status:          ACTIVE
│ Version:         1.28
│ Endpoint:        https://1E25F8C93ACAA2E6DE45E360E8888F47.gr7.us-east-1.eks.amazonaws.com
│ Worker Nodes:    2
└────────────────────────────────────────────────────────────────┘

🔐 ACCESS CONFIGURATION:
┌────────────────────────────────────────────────────────────────┐
│ Update kubeconfig:
│   aws eks update-kubeconfig --name flask-eks --region us-east-1
│
│ Verify access:
│   kubectl cluster-info
│   kubectl get nodes
└────────────────────────────────────────────────────────────────┘

📦 DEPLOYED RESOURCES:
├─ VPC ID: vpc-xxxxxxxxxxxxxxxxx
├─ EKS Cluster: flask-eks
├─ OIDC Provider: oidc.eks.us-east-1.amazonaws.com/id/xxxxx
├─ Worker Nodes: 2 (t3.medium)
├─ Load Balancer Controller: Installed
├─ EBS CSI Driver: Installed
└─ VPC CNI: Installed

🎯 NEXT STEPS:
1. Update kubeconfig (command above)
2. Deploy application:
   kubectl apply -f k8s/
3. Deploy monitoring:
   Run 'Deploy Monitoring Stack' workflow
4. Get application URL:
   kubectl get ingress -n default

💰 ESTIMATED MONTHLY COST: ~$255
├─ EKS Cluster: ~$73/month
├─ EC2 Instances: ~$60/month
├─ NAT Gateways: ~$100/month
├─ Load Balancers: ~$20/month
└─ Other: ~$2/month
```

### **After Successful Destroy:**

```
╔════════════════════════════════════════════════════════════════╗
║        INFRASTRUCTURE DESTROYED SUCCESSFULLY! ✅               ║
╚════════════════════════════════════════════════════════════════╝

🗑️  DELETED RESOURCES:
├─ EKS Cluster: flask-eks
├─ Worker Nodes: All terminated
├─ VPC and Subnets: Deleted
├─ NAT Gateways: Deleted
├─ Load Balancers: Deleted
├─ Security Groups: Deleted
├─ IAM Roles: Deleted
└─ All associated resources: Deleted

💰 COST SAVINGS: ~$255/month

⚠️  NOTE:
- All data has been permanently deleted
- Resources cannot be recovered
- Verify in AWS Console that all resources are gone

🔄 TO RECREATE:
Run this workflow again with action: 'apply'
```

---

## 📈 GitHub Actions Summary

The workflow creates a detailed summary:

### **Apply Summary:**

| Property | Value |
|----------|-------|
| **Cluster Name** | flask-eks |
| **Region** | us-east-1 |
| **Status** | ACTIVE |
| **Version** | 1.28 |
| **Worker Nodes** | 2 |
| **VPC ID** | vpc-xxxxx |

**Access Commands:**
```bash
aws eks update-kubeconfig --name flask-eks --region us-east-1
kubectl cluster-info
kubectl get nodes
```

**Deployed Components:**
- ✅ VPC with public/private subnets
- ✅ EKS Cluster
- ✅ Worker Nodes (2x t3.medium)
- ✅ AWS Load Balancer Controller
- ✅ EBS CSI Driver
- ✅ VPC CNI Plugin
- ✅ OIDC Provider

---

## 🔧 Configuration

### **Environment Variables:**

Edit in workflow file:
```yaml
env:
  AWS_REGION: us-east-1
  TF_VERSION: '1.6.0'
  WORKING_DIR: terraform-eks
```

### **Terraform Variables:**

Edit `terraform-eks/terraform.tfvars`:
```hcl
cluster_name    = "flask-eks"
cluster_version = "1.28"
region          = "us-east-1"
vpc_cidr        = "10.0.0.0/16"

node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
  }
}
```

---

## 📚 Workflow Jobs

### **Job 1: Terraform Operations**

**Steps:**
1. Checkout code
2. Configure AWS credentials (OIDC)
3. Setup Terraform
4. Format check
5. Initialize Terraform
6. Validate configuration
7. **Plan / Apply / Destroy** (based on input)
8. Get infrastructure outputs
9. Update kubeconfig
10. Get cluster information
11. Display infrastructure info
12. Create deployment summary

### **Job 2: Post-Apply Verification**

**Steps:**
1. Verify EKS cluster status
2. Check worker nodes
3. Verify addons (VPC CNI, CoreDNS, kube-proxy, EBS CSI)
4. Verify Load Balancer Controller
5. Create verification summary

---

## 🎯 Use Cases

### **Use Case 1: Initial Infrastructure Setup**

```yaml
Action: apply
Auto-approve: ✅ (for automation)

Result:
✅ EKS cluster created
✅ Worker nodes launched
✅ Networking configured
✅ Addons installed
✅ Ready for application deployment
```

### **Use Case 2: Infrastructure Update**

```bash
# 1. Edit terraform files
# 2. Commit and push
git add terraform-eks/
git commit -m "Update node count to 3"
git push origin main

# 3. Run workflow
Action: plan (review changes)
# Then
Action: apply (apply changes)
```

### **Use Case 3: Cleanup**

```yaml
Action: destroy
Auto-approve: ✅ (if sure) or ⬜ (for safety)

Result:
✅ All resources deleted
✅ Costs stopped
✅ Clean slate
```

---

## 🐛 Troubleshooting

### **Issue 1: Apply Fails with "Cluster Unreachable"**

**Cause:** Helm provider trying to connect to non-existent cluster

**Solution:**
```bash
# Remove Helm release from state
terraform state rm helm_release.aws_load_balancer_controller

# Re-run apply
```

### **Issue 2: Destroy Hangs**

**Possible Causes:**
- Load Balancers still exist
- Security Groups in use
- ENIs not deleted

**Solution:**
```bash
# Manually delete Load Balancers
aws elbv2 describe-load-balancers --region us-east-1
aws elbv2 delete-load-balancer --load-balancer-arn <ARN>

# Wait 2-3 minutes, then re-run destroy
```

### **Issue 3: Nodes Not Ready**

**Check:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```

**Common fixes:**
- Wait 5-10 minutes for nodes to initialize
- Check VPC CNI addon status
- Verify security groups allow node communication

### **Issue 4: OIDC Authentication Fails**

**Check:**
```bash
# Verify OIDC provider exists
aws iam list-open-id-connect-providers

# Check trust policy
aws iam get-role --role-name github-deployer-role
```

---

## 🔐 Security Best Practices

### **1. Use OIDC (No Long-lived Credentials)**

Already configured:
```yaml
permissions:
  id-token: write
  contents: read

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
```

### **2. Protect Main Branch**

```
Settings → Branches → Add rule
Branch name pattern: main
✓ Require pull request reviews
✓ Require status checks to pass
```

### **3. Require Manual Approval for Destroy**

**Don't auto-approve destroy:**
```yaml
# ❌ Dangerous
auto_approve: true

# ✅ Safe
auto_approve: false
```

### **4. Use Terraform State Locking**

Already configured in backend:
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-816069153839"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

## 📊 Cost Management

### **Estimated Costs:**

| Resource | Monthly Cost |
|----------|--------------|
| EKS Cluster | $73 |
| EC2 Instances (2x t3.medium) | $60 |
| NAT Gateways (3x) | $100 |
| Application Load Balancers | $20 |
| EBS Volumes | $2 |
| **Total** | **~$255** |

### **Cost Optimization:**

**Reduce NAT Gateway costs:**
```hcl
# Use single NAT Gateway
enable_nat_gateway     = true
single_nat_gateway     = true  # Instead of one per AZ
one_nat_gateway_per_az = false
```

**Use Spot Instances:**
```hcl
node_groups = {
  spot = {
    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"
    min_size       = 2
    max_size       = 4
  }
}
```

---

## 🎯 Complete Deployment Flow

### **Step 1: Deploy Infrastructure**
```
Run workflow: action = apply
Wait: 15-20 minutes
Result: EKS cluster ready
```

### **Step 2: Update Kubeconfig**
```bash
aws eks update-kubeconfig --name flask-eks --region us-east-1
kubectl get nodes
```

### **Step 3: Deploy Application**
```
Run workflow: build-deploy-app.yml
Wait: 5 minutes
Result: Application deployed
```

### **Step 4: Deploy Monitoring**
```
Run workflow: deploy-monitoring.yml
Wait: 10 minutes
Result: Grafana accessible
```

### **Step 5: Get URLs**
```bash
# Application URL
kubectl get ingress -n default

# Grafana URL
kubectl get svc -n monitoring prometheus-stack-grafana
```

---

## ✅ Checklist

**Before Apply:**
- [ ] AWS credentials configured
- [ ] Terraform state backend exists
- [ ] terraform.tfvars is correct
- [ ] Reviewed plan output

**After Apply:**
- [ ] Cluster status is ACTIVE
- [ ] Worker nodes are Ready
- [ ] Addons are installed
- [ ] kubeconfig updated
- [ ] Can access cluster with kubectl

**Before Destroy:**
- [ ] Backed up any important data
- [ ] Deleted application resources
- [ ] Deleted monitoring stack
- [ ] Confirmed with team
- [ ] Ready for costs to stop

---

## 🚀 Quick Start

**Deploy infrastructure in 3 steps:**

1. **Go to Actions:**
   ```
   https://github.com/yuvanreddy/flask-app-update/actions
   ```

2. **Select "Terraform Infrastructure Management"**

3. **Run workflow:**
   - Action: `apply`
   - Auto-approve: ✅
   - Click "Run workflow"

4. **Wait 15-20 minutes**

5. **Check Summary for cluster info!** ⭐

6. **Update kubeconfig and deploy apps!** 🚀

---

**Created:** October 9, 2025  
**Workflow Version:** 1.0  
**Status:** Ready to use
