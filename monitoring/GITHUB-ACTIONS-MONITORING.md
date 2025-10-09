# GitHub Actions - Monitoring Deployment

**Workflow File:** `.github/workflows/deploy-monitoring.yml`  
**Purpose:** Automated deployment of Prometheus + Grafana monitoring stack  
**Date:** October 9, 2025

---

## 🚀 Features

### **Automated Deployment:**
- ✅ Install Prometheus + Grafana stack
- ✅ Apply custom Flask app alerts
- ✅ Display access URLs and credentials
- ✅ Verify deployment health
- ✅ Create deployment summary

### **Flexible Actions:**
- **Install** - Fresh installation
- **Upgrade** - Update existing installation
- **Uninstall** - Remove monitoring stack
- **Status** - Check current status

### **Automatic Triggers:**
- Manual workflow dispatch
- Push to `main` branch (monitoring files changed)

---

## 📋 Prerequisites

### **1. AWS Credentials**
Ensure `AWS_ROLE_TO_ASSUME` secret is configured:
```
Settings → Secrets and variables → Actions → New repository secret
Name: AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::816069153839:role/github-deployer-role
```

### **2. EKS Cluster**
- Cluster name: `flask-eks`
- Region: `us-east-1`
- Cluster must be running

### **3. Required Files**
- `monitoring/prometheus-values.yaml`
- `monitoring/flask-app-alerts.yaml`

---

## 🎯 How to Use

### **Method 1: Manual Trigger (Recommended)**

1. **Go to GitHub Actions:**
   ```
   Your Repository → Actions → Deploy Monitoring Stack
   ```

2. **Click "Run workflow"**

3. **Select action:**
   - `install` - First time installation
   - `upgrade` - Update existing installation
   - `uninstall` - Remove monitoring
   - `status` - Check current status

4. **Optional: Set Grafana password**
   - Leave empty to use default
   - Or enter custom password

5. **Click "Run workflow"**

### **Method 2: Automatic Trigger**

Push changes to monitoring files:
```bash
git add monitoring/
git commit -m "Update monitoring configuration"
git push origin main
```

Workflow will automatically run and install/upgrade monitoring.

---

## 📊 Workflow Steps

### **Job 1: Deploy Monitoring**

1. **Checkout code**
2. **Configure AWS credentials** (OIDC)
3. **Install kubectl and Helm**
4. **Update kubeconfig** (connect to EKS)
5. **Add Prometheus Helm repository**
6. **Create monitoring namespace**
7. **Install/Upgrade Prometheus stack**
8. **Apply custom alerts**
9. **Wait for pods to be ready**
10. **Get monitoring status**
11. **Display access information** ⭐
12. **Create deployment summary** ⭐

### **Job 2: Verify Monitoring**

1. **Verify Prometheus** (health check)
2. **Verify Grafana** (health check)
3. **Verify Alertmanager** (health check)
4. **Verify custom alerts** (configuration check)
5. **Create verification summary**

---

## 🌐 Output Information

### **Console Output:**

After successful deployment, you'll see:

```
╔════════════════════════════════════════════════════════════════╗
║          MONITORING STACK DEPLOYMENT SUCCESSFUL! 🎉            ║
╚════════════════════════════════════════════════════════════════╝

📊 MONITORING STACK STATUS:
├─ Total Pods: 7
├─ Ready Pods: 7
├─ Alert Rules: 34
└─ Namespace: monitoring

🌐 ACCESS INFORMATION:
┌────────────────────────────────────────────────────────────────┐
│ GRAFANA DASHBOARD                                              │
├────────────────────────────────────────────────────────────────┤
│ URL:      http://k8s-monitori-promethe-xxxxx.elb.us-east-1.amazonaws.com
│ Username: admin
│ Password: ChangeMe123!SecurePassword
└────────────────────────────────────────────────────────────────┘

🔍 PORT FORWARD ACCESS (Alternative):
┌────────────────────────────────────────────────────────────────┐
│ Grafana:                                                       │
│   kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
│   http://localhost:3000                                        │
│                                                                │
│ Prometheus:                                                    │
│   kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
│   http://localhost:9090                                        │
│                                                                │
│ Alertmanager:                                                  │
│   kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093
│   http://localhost:9093                                        │
└────────────────────────────────────────────────────────────────┘

📚 NEXT STEPS:
1. Access Grafana using the URL above
2. Login with admin credentials
3. Import recommended dashboards (IDs: 7249, 1860, 6417)
4. Configure alert notifications (email/Slack)
5. Create custom Flask app dashboard
```

### **GitHub Actions Summary:**

The workflow creates a detailed summary in the Actions UI:

**Deployment Status:**
| Component | Status |
|-----------|--------|
| Prometheus | ✅ Deployed |
| Grafana | ✅ Deployed |
| Alertmanager | ✅ Deployed |
| Node Exporter | ✅ Deployed |
| Kube State Metrics | ✅ Deployed |
| Custom Alerts | ✅ Applied |

**Access Information:**
- Grafana URL with credentials
- Port forward commands
- Recommended dashboards
- Next steps

---

## 🔧 Configuration

### **Environment Variables:**

Edit in workflow file:
```yaml
env:
  AWS_REGION: us-east-1
  EKS_CLUSTER_NAME: flask-eks
  MONITORING_NAMESPACE: monitoring
  HELM_CHART_VERSION: "55.0.0"
```

### **Grafana Password:**

**Option 1: Use default**
- Leave input empty
- Default: `ChangeMe123!SecurePassword`

**Option 2: Custom password**
- Enter in workflow input
- Will update `prometheus-values.yaml`

**Option 3: GitHub Secret**
- Create secret: `GRAFANA_ADMIN_PASSWORD`
- Update workflow to use: `${{ secrets.GRAFANA_ADMIN_PASSWORD }}`

---

## 📚 Examples

### **Example 1: First Time Installation**

```yaml
# Trigger: Manual workflow dispatch
Action: install
Grafana Password: (leave empty or enter custom)

# Result:
✅ Prometheus stack installed
✅ Custom alerts applied
✅ URLs displayed in console
✅ Summary created
```

### **Example 2: Update Configuration**

```bash
# 1. Edit monitoring/prometheus-values.yaml
# 2. Commit and push
git add monitoring/prometheus-values.yaml
git commit -m "Update Grafana retention to 30 days"
git push origin main

# 3. Workflow automatically runs
# 4. Monitoring stack upgraded
```

### **Example 3: Uninstall Monitoring**

```yaml
# Trigger: Manual workflow dispatch
Action: uninstall

# Result:
✅ Helm release uninstalled
✅ Namespace deleted
✅ All monitoring resources removed
```

---

## 🐛 Troubleshooting

### **Issue 1: Workflow Fails at "Install Prometheus Stack"**

**Possible Causes:**
- EKS cluster not accessible
- Insufficient permissions
- Helm chart version not available

**Solution:**
```bash
# Check cluster status
aws eks describe-cluster --name flask-eks --region us-east-1

# Verify OIDC role
aws iam get-role --role-name github-deployer-role

# Check available Helm versions
helm search repo prometheus-community/kube-prometheus-stack --versions
```

### **Issue 2: Grafana LoadBalancer URL is "pending"**

**Cause:** LoadBalancer provisioning takes 2-3 minutes

**Solution:**
Wait a few minutes, then check:
```bash
kubectl get svc -n monitoring prometheus-stack-grafana
```

### **Issue 3: Pods Not Ready**

**Check pod status:**
```bash
kubectl get pods -n monitoring
kubectl describe pod <pod-name> -n monitoring
kubectl logs <pod-name> -n monitoring
```

**Common fixes:**
- Increase timeout in workflow
- Check resource limits
- Verify storage class exists

### **Issue 4: Custom Alerts Not Applied**

**Check:**
```bash
kubectl get prometheusrules -n monitoring flask-app-alerts
kubectl describe prometheusrules -n monitoring flask-app-alerts
```

**Fix:**
```bash
# Manually apply
kubectl apply -f monitoring/flask-app-alerts.yaml
```

---

## 🔐 Security Best Practices

### **1. Protect Grafana Password**

**Don't hardcode in values file:**
```yaml
# ❌ Bad
grafana:
  adminPassword: "MyPassword123"

# ✅ Good - Use GitHub Secret
grafana:
  adminPassword: ${{ secrets.GRAFANA_ADMIN_PASSWORD }}
```

### **2. Use OIDC for AWS Authentication**

Already configured in workflow:
```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
```

### **3. Limit Workflow Permissions**

Only grant necessary permissions:
```yaml
permissions:
  id-token: write    # For OIDC
  contents: read     # For checkout
```

### **4. Use Branch Protection**

Require approval for monitoring changes:
```
Settings → Branches → Add rule
Branch name pattern: main
✓ Require pull request reviews before merging
```

---

## 📊 Monitoring the Monitoring

### **Check Workflow Status:**

```bash
# Via GitHub CLI
gh run list --workflow=deploy-monitoring.yml

# View latest run
gh run view

# View logs
gh run view --log
```

### **Check Deployment:**

```bash
# Get all monitoring resources
kubectl get all -n monitoring

# Check Helm release
helm list -n monitoring

# Check PVCs
kubectl get pvc -n monitoring
```

---

## 🎯 Advanced Usage

### **Custom Helm Values:**

Create environment-specific values:

```yaml
# monitoring/values-production.yaml
grafana:
  replicas: 2
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi

prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 100Gi
```

Update workflow:
```yaml
helm install prometheus-stack ... \
  --values monitoring/prometheus-values.yaml \
  --values monitoring/values-production.yaml
```

### **Multi-Environment Deployment:**

Add environment input:
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options:
          - development
          - staging
          - production
```

Use in workflow:
```yaml
- name: Set environment
  run: |
    if [ "${{ github.event.inputs.environment }}" == "production" ]; then
      echo "MONITORING_NAMESPACE=monitoring-prod" >> $GITHUB_ENV
    else
      echo "MONITORING_NAMESPACE=monitoring-dev" >> $GITHUB_ENV
    fi
```

---

## 📖 Related Documentation

- [Monitoring Integration Guide](MONITORING-INTEGRATION-GUIDE.md)
- [PromQL Queries](FLASK-APP-PROMQL-QUERIES.md)
- [Dashboard Creation Guide](GRAFANA-DASHBOARD-CREATION-GUIDE.md)
- [Alerts and Notifications](ALERTS-AND-NOTIFICATIONS-GUIDE.md)

---

## ✅ Checklist

**Before Running Workflow:**
- [ ] EKS cluster is running
- [ ] AWS_ROLE_TO_ASSUME secret is configured
- [ ] monitoring/prometheus-values.yaml exists
- [ ] monitoring/flask-app-alerts.yaml exists

**After Deployment:**
- [ ] Check workflow summary for URLs
- [ ] Access Grafana dashboard
- [ ] Verify all pods are running
- [ ] Import recommended dashboards
- [ ] Configure alert notifications

---

## 🎉 Quick Start

**Deploy monitoring in 3 steps:**

1. **Go to Actions tab**
   ```
   https://github.com/yuvanreddy/flask-app-update/actions
   ```

2. **Select "Deploy Monitoring Stack"**

3. **Click "Run workflow" → Select "install" → Run**

4. **Wait 5-10 minutes**

5. **Check summary for Grafana URL and credentials**

6. **Access Grafana and start monitoring!** 🚀

---

**Created:** October 9, 2025  
**Workflow Version:** 1.0  
**Status:** Ready to use
