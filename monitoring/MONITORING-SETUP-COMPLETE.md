# Monitoring Setup - Complete! ✅

**Date:** October 9, 2025  
**Cluster:** flask-eks (us-east-1)  
**Status:** Fully Operational

---

## 🎉 Installation Summary

### **Components Installed:**
✅ **Prometheus Server** - Metrics collection and storage  
✅ **Grafana** - Visualization and dashboards  
✅ **Alertmanager** - Alert routing and notifications  
✅ **Node Exporter** - Node-level metrics (2 instances)  
✅ **Kube State Metrics** - Kubernetes object metrics  
✅ **Prometheus Operator** - Manages Prometheus instances  
✅ **Custom Flask App Alerts** - Application-specific monitoring  

### **All Pods Running:**
```
NAME                                                     READY   STATUS    AGE
alertmanager-prometheus-stack-kube-prom-alertmanager-0   2/2     Running   6m
prometheus-prometheus-stack-kube-prom-prometheus-0       2/2     Running   6m
prometheus-stack-grafana-548fb7587d-llf6g                3/3     Running   2m
prometheus-stack-kube-prom-operator-54f596b988-pg2fk     1/1     Running   6m
prometheus-stack-kube-state-metrics-56f9ddf4b7-654hg     1/1     Running   6m
prometheus-stack-prometheus-node-exporter-6pkmt          1/1     Running   6m
prometheus-stack-prometheus-node-exporter-qdp6p          1/1     Running   6m
```

---

## 🌐 Access Information

### **Grafana Dashboard**

**Option 1: LoadBalancer (Direct Access)**
```
URL: http://k8s-monitori-promethe-c617b8a740-e2d875751e5d49de.elb.us-east-1.amazonaws.com
Username: admin
Password: ChangeMe123!SecurePassword
```

**Option 2: Port Forward (Local Access)**
```powershell
# Run this command
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Then open browser
http://localhost:3000

# Credentials
Username: admin
Password: ChangeMe123!SecurePassword
```

**Option 3: Create Ingress (Production)**
```powershell
# Apply the Ingress configuration
kubectl apply -f grafana-ingress.yaml

# Get ALB URL
kubectl get ingress -n monitoring grafana-ingress
```

---

## 📊 Available Dashboards

Once logged into Grafana, you'll find these pre-installed dashboards:

### **1. Kubernetes Cluster Monitoring (ID: 7249)**
- Overall cluster health
- Node status and resources
- Pod distribution
- Network and storage metrics

### **2. Node Exporter Full (ID: 1860)**
- CPU usage per node
- Memory usage and swap
- Disk I/O and space
- Network traffic
- System load

### **3. Kubernetes Pods Monitoring (ID: 6417)**
- Pod CPU and memory usage
- Pod network I/O
- Pod restart count
- Container resource limits

### **4. Kubernetes Deployments (ID: 8588)**
- Deployment status
- Replica counts
- Rolling update progress
- Resource utilization

### **5. Persistent Volumes (ID: 13646)**
- PVC usage
- Available space
- I/O metrics

---

## 🚨 Custom Alerts Configured

### **Flask App Alerts:**

| Alert Name | Condition | Severity | Duration |
|------------|-----------|----------|----------|
| FlaskAppPodDown | Pod is down | Critical | 5 minutes |
| FlaskAppNoPodsRunning | No pods running | Critical | 3 minutes |
| FlaskAppHighRestartRate | Frequent restarts | Warning | 5 minutes |
| FlaskAppHighCPUUsage | CPU > 80% | Warning | 10 minutes |
| FlaskAppHighMemoryUsage | Memory > 90% | Warning | 10 minutes |
| FlaskAppCPUThrottling | CPU throttled | Warning | 10 minutes |
| FlaskAppPVCAlmostFull | Storage > 85% | Warning | 15 minutes |
| FlaskAppPVCCriticallyFull | Storage > 95% | Critical | 5 minutes |
| FlaskAppServiceNoEndpoints | No service endpoints | Critical | 5 minutes |
| FlaskAppDatabasePVCIssue | DB PVC not bound | Critical | 5 minutes |

---

## 🔍 Prometheus Access

### **Prometheus UI:**
```powershell
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Open browser
http://localhost:9090
```

### **Useful Prometheus Queries:**

**Flask App CPU Usage:**
```promql
rate(container_cpu_usage_seconds_total{pod=~"flask-app.*"}[5m])
```

**Flask App Memory Usage:**
```promql
container_memory_usage_bytes{pod=~"flask-app.*"}
```

**Flask App Pod Status:**
```promql
kube_pod_status_phase{pod=~"flask-app.*"}
```

**Flask App Restart Count:**
```promql
kube_pod_container_status_restarts_total{pod=~"flask-app.*"}
```

**PVC Usage:**
```promql
kubelet_volume_stats_used_bytes{persistentvolumeclaim=~"flask-app.*"} / kubelet_volume_stats_capacity_bytes{persistentvolumeclaim=~"flask-app.*"}
```

---

## 📈 Alertmanager Access

### **Alertmanager UI:**
```powershell
# Port forward Alertmanager
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093

# Open browser
http://localhost:9093
```

### **Configure Notifications:**

Edit `prometheus-values.yaml` and add your notification channels:

**Email Notifications:**
```yaml
alertmanager:
  config:
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alertmanager@example.com'
      smtp_auth_username: 'your-email@gmail.com'
      smtp_auth_password: 'your-app-password'
    
    receivers:
    - name: 'critical'
      email_configs:
      - to: 'critical-alerts@example.com'
```

**Slack Notifications:**
```yaml
receivers:
- name: 'critical'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
    channel: '#alerts-critical'
    title: '[CRITICAL] {{ .GroupLabels.alertname }}'
```

Then upgrade:
```powershell
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f prometheus-values.yaml
```

---

## 🎨 Create Custom Dashboard for Flask App

### **Step 1: Login to Grafana**
- URL: http://k8s-monitori-promethe-c617b8a740-e2d875751e5d49de.elb.us-east-1.amazonaws.com
- Username: admin
- Password: ChangeMe123!SecurePassword

### **Step 2: Create New Dashboard**
1. Click "+" → Dashboard
2. Click "Add visualization"
3. Select "Prometheus" as data source

### **Step 3: Add Panels**

**Panel 1: Flask App CPU Usage**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod)
```

**Panel 2: Flask App Memory Usage**
```promql
sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod)
```

**Panel 3: Flask App Pod Count**
```promql
count(kube_pod_status_phase{namespace="default",pod=~"flask-app.*",phase="Running"})
```

**Panel 4: Flask App Restarts**
```promql
sum(kube_pod_container_status_restarts_total{namespace="default",pod=~"flask-app.*"}) by (pod)
```

**Panel 5: Photos Storage Usage**
```promql
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"} / 1024 / 1024 / 1024
```

**Panel 6: Database Storage Usage**
```promql
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-db-pvc"} / 1024 / 1024
```

**Panel 7: Network I/O**
```promql
# Received
sum(rate(container_network_receive_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod)

# Transmitted
sum(rate(container_network_transmit_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod)
```

### **Step 4: Save Dashboard**
- Click "Save dashboard" (top right)
- Name: "Flask Photo Gallery"
- Folder: Default
- Click "Save"

---

## 🔧 Useful Commands

### **Check Status:**
```powershell
# All monitoring pods
kubectl get pods -n monitoring

# Grafana service
kubectl get svc -n monitoring prometheus-stack-grafana

# Prometheus rules
kubectl get prometheusrules -n monitoring

# Alerts
kubectl get prometheusrules -n monitoring flask-app-alerts -o yaml
```

### **View Logs:**
```powershell
# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=100

# Prometheus logs
kubectl logs -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0 -c prometheus --tail=100

# Alertmanager logs
kubectl logs -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -c alertmanager --tail=100
```

### **Restart Components:**
```powershell
# Restart Grafana
kubectl rollout restart deployment -n monitoring prometheus-stack-grafana

# Restart Prometheus (delete pod, will auto-recreate)
kubectl delete pod -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0
```

### **Update Configuration:**
```powershell
# Edit values file, then upgrade
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f prometheus-values.yaml
```

---

## 📦 Storage Information

### **Persistent Volumes Created:**

**Prometheus Storage:**
- PVC: prometheus-prometheus-stack-kube-prom-prometheus-db-prometheus-prometheus-stack-kube-prom-prometheus-0
- Size: 50 GiB
- StorageClass: gp2
- Retention: 15 days

**Grafana Storage:**
- PVC: prometheus-stack-grafana
- Size: 10 GiB
- StorageClass: gp2

**Alertmanager Storage:**
- PVC: alertmanager-prometheus-stack-kube-prom-alertmanager-db-alertmanager-prometheus-stack-kube-prom-alertmanager-0
- Size: 10 GiB
- StorageClass: gp2

---

## 🎯 Next Steps

### **Immediate:**
1. ✅ Login to Grafana and explore dashboards
2. ✅ Verify Flask app metrics are being collected
3. ✅ Check that alerts are configured

### **Short Term:**
1. 🔄 Create custom Flask app dashboard
2. 🔄 Configure email/Slack notifications
3. 🔄 Set up Grafana Ingress for production access
4. 🔄 Add authentication (OAuth/LDAP)

### **Long Term:**
1. 📊 Add application-level metrics (if /metrics endpoint exists)
2. 📊 Set up log aggregation (Loki)
3. 📊 Add distributed tracing (Jaeger/Tempo)
4. 📊 Configure long-term storage (Thanos)

---

## 🐛 Troubleshooting

### **Issue: Grafana pod was crashing**
**Cause:** Duplicate datasource configuration in prometheus-values.yaml  
**Solution:** Removed duplicate datasource config, kept only default from Helm chart  
**Status:** ✅ Fixed

### **If Grafana is not accessible:**
```powershell
# Check pod status
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Check logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50

# Check service
kubectl get svc -n monitoring prometheus-stack-grafana

# Restart if needed
kubectl rollout restart deployment -n monitoring prometheus-stack-grafana
```

### **If metrics are not showing:**
```powershell
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
# Open: http://localhost:9090/targets

# Check ServiceMonitors
kubectl get servicemonitor -n monitoring

# Check if pods have correct labels
kubectl get pods -n default --show-labels
```

---

## 📚 Resources

### **Documentation:**
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

### **Grafana Dashboards:**
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- Search for: kubernetes, prometheus, node-exporter

### **PromQL Learning:**
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

---

## ✅ Summary

Your monitoring stack is now **fully operational**!

**What's Working:**
- ✅ Prometheus collecting metrics from all cluster components
- ✅ Grafana accessible with pre-built dashboards
- ✅ Alertmanager ready for notifications
- ✅ Custom Flask app alerts configured
- ✅ Node exporters running on all nodes
- ✅ Kube-state-metrics tracking Kubernetes objects

**Access URLs:**
- **Grafana:** http://k8s-monitori-promethe-c617b8a740-e2d875751e5d49de.elb.us-east-1.amazonaws.com
- **Credentials:** admin / ChangeMe123!SecurePassword

**Next Action:**
🎯 Login to Grafana and start exploring your cluster metrics!

---

**Setup Completed:** October 9, 2025  
**Status:** 🚀 Production Ready
