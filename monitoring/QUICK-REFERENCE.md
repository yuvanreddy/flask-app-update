# Monitoring Quick Reference Card

**Quick access guide for monitoring deployment and URLs**

---

## 🚀 Deploy Monitoring (GitHub Actions)

### **Quick Deploy:**
```
1. Go to: https://github.com/yuvanreddy/flask-app-update/actions
2. Click: "Deploy Monitoring Stack"
3. Click: "Run workflow"
4. Select: "install"
5. Click: "Run workflow" button
6. Wait: 5-10 minutes
7. Check: Summary tab for URLs
```

### **Actions Available:**
| Action | Purpose | When to Use |
|--------|---------|-------------|
| `install` | Fresh installation | First time setup |
| `upgrade` | Update configuration | After changing values |
| `uninstall` | Remove monitoring | Cleanup |
| `status` | Check current state | Verification |

---

## 🌐 Access URLs

### **After Deployment, Find URLs In:**

**Option 1: GitHub Actions Summary**
```
Actions → Deploy Monitoring Stack → Latest run → Summary tab
```

**Option 2: Workflow Console Output**
```
Actions → Deploy Monitoring Stack → Latest run → deploy-monitoring job
Scroll to "Display access information" step
```

**Option 3: Command Line**
```bash
# Get Grafana URL
kubectl get svc -n monitoring prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get Grafana password
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

---

## 📊 Default Access Information

### **Grafana:**
```
URL:      http://k8s-monitori-promethe-[UNIQUE-ID].elb.us-east-1.amazonaws.com
Username: admin
Password: ChangeMe123!SecurePassword (or custom if set)
```

### **Prometheus (Port Forward):**
```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
# Access: http://localhost:9090
```

### **Alertmanager (Port Forward):**
```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093
# Access: http://localhost:9093
```

---

## 📈 Recommended Dashboards to Import

Once in Grafana, import these:

| ID | Dashboard Name | Purpose |
|----|----------------|---------|
| 7249 | Kubernetes Cluster | Overall cluster health |
| 1860 | Node Exporter Full | Node-level metrics |
| 6417 | Kubernetes Pods | Pod monitoring |
| 8588 | Kubernetes Deployments | Deployment status |
| 13646 | Kubernetes PV | Storage monitoring |

**How to Import:**
```
Grafana → + → Import → Enter ID → Load → Import
```

---

## 🚨 Custom Alerts Configured

| Alert | Condition | Severity |
|-------|-----------|----------|
| FlaskAppPodDown | Pod down >5min | Critical |
| FlaskAppHighCPU | CPU >80% for 10min | Warning |
| FlaskAppHighMemory | Memory >90% for 10min | Warning |
| FlaskAppPVCAlmostFull | Storage >85% | Warning |
| FlaskAppNoPodsRunning | No pods for 3min | Critical |

**View Alerts:**
- Prometheus: http://localhost:9090/alerts
- Alertmanager: http://localhost:9093
- Grafana: Alerting → Alert rules

---

## 🔧 Quick Commands

### **Check Status:**
```bash
# All monitoring pods
kubectl get pods -n monitoring

# Helm release
helm list -n monitoring

# Services
kubectl get svc -n monitoring

# Alert rules
kubectl get prometheusrules -n monitoring
```

### **View Logs:**
```bash
# Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50

# Prometheus
kubectl logs -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0 -c prometheus --tail=50

# Alertmanager
kubectl logs -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -c alertmanager --tail=50
```

### **Restart Components:**
```bash
# Restart Grafana
kubectl rollout restart deployment -n monitoring prometheus-stack-grafana

# Restart Prometheus (delete pod, auto-recreates)
kubectl delete pod -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0
```

---

## 🎯 Common Tasks

### **Task 1: Change Grafana Password**

```bash
# Get current password
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Or change via Grafana UI:
# Profile → Change Password
```

### **Task 2: Configure Email Alerts**

```yaml
# Edit: monitoring/prometheus-values.yaml
alertmanager:
  config:
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'your-email@gmail.com'
      smtp_auth_username: 'your-email@gmail.com'
      smtp_auth_password: 'your-app-password'
    receivers:
    - name: 'default'
      email_configs:
      - to: 'alerts@yourdomain.com'
```

Then run workflow with action: `upgrade`

### **Task 3: Add Custom Dashboard**

```
1. Login to Grafana
2. Click + → Dashboard
3. Add visualization
4. Select Prometheus
5. Enter PromQL query
6. Save dashboard
```

---

## 📖 Documentation Links

| Document | Purpose |
|----------|---------|
| [GITHUB-ACTIONS-MONITORING.md](GITHUB-ACTIONS-MONITORING.md) | Workflow guide |
| [MONITORING-INTEGRATION-GUIDE.md](MONITORING-INTEGRATION-GUIDE.md) | Complete setup |
| [FLASK-APP-PROMQL-QUERIES.md](FLASK-APP-PROMQL-QUERIES.md) | 59 PromQL queries |
| [GRAFANA-DASHBOARD-CREATION-GUIDE.md](GRAFANA-DASHBOARD-CREATION-GUIDE.md) | Dashboard creation |
| [ALERTS-AND-NOTIFICATIONS-GUIDE.md](ALERTS-AND-NOTIFICATIONS-GUIDE.md) | Alerts setup |

---

## 🆘 Troubleshooting

### **Issue: Can't access Grafana URL**

```bash
# Check if LoadBalancer is ready
kubectl get svc -n monitoring prometheus-stack-grafana

# If pending, wait 2-3 minutes
# Or use port forward:
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
# Access: http://localhost:3000
```

### **Issue: Forgot Grafana password**

```bash
# Get password from secret
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

### **Issue: Pods not running**

```bash
# Check pod status
kubectl get pods -n monitoring

# Describe problematic pod
kubectl describe pod <pod-name> -n monitoring

# Check logs
kubectl logs <pod-name> -n monitoring
```

### **Issue: Alerts not firing**

```bash
# Check alert rules
kubectl get prometheusrules -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
# Open: http://localhost:9090/targets
```

---

## ⚡ One-Liners

```bash
# Deploy monitoring
gh workflow run deploy-monitoring.yml -f action=install

# Get Grafana URL
kubectl get svc -n monitoring prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get Grafana password
kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Check all monitoring pods
kubectl get pods -n monitoring

# Port forward all services
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80 &
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093 &

# Uninstall monitoring
gh workflow run deploy-monitoring.yml -f action=uninstall
```

---

## 📱 Mobile Quick Access

**Bookmark these after deployment:**

1. Grafana Dashboard
2. Prometheus UI
3. Alertmanager UI
4. GitHub Actions page

**QR Code for Grafana:**
(Generate after getting URL)

---

**Last Updated:** October 9, 2025  
**Version:** 1.0
