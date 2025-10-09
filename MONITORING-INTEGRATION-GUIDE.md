# Monitoring Integration Guide
**Flask Photo Gallery - EKS Cluster Monitoring**  
**Cluster:** flask-eks (us-east-1)  
**Date:** October 9, 2025

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Option 1: Prometheus + Grafana (Recommended)](#option-1-prometheus--grafana-recommended)
3. [Option 2: Rancher Integration](#option-2-rancher-integration)
4. [Option 3: AWS Native Monitoring](#option-3-aws-native-monitoring)
5. [Comparison Matrix](#comparison-matrix)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This guide covers three monitoring solutions for your EKS cluster:

| Solution | Best For | Complexity | Cost |
|----------|----------|------------|------|
| **Prometheus + Grafana** | Kubernetes-native monitoring | Medium | Free (self-hosted) |
| **Rancher** | Multi-cluster management + monitoring | High | Free (self-hosted) |
| **AWS CloudWatch** | AWS-native, simple setup | Low | Pay-per-use |

---

## 🔥 Option 1: Prometheus + Grafana (Recommended)

### **Why This Option?**
- ✅ Industry standard for Kubernetes monitoring
- ✅ Free and open-source
- ✅ Rich ecosystem of exporters
- ✅ Beautiful pre-built dashboards
- ✅ Integrates seamlessly with EKS

### **Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│                    EKS Cluster (flask-eks)                   │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Prometheus Stack (kube-prometheus-stack)          │     │
│  │                                                     │     │
│  │  ┌──────────────────────────────────────────┐      │     │
│  │  │  Prometheus Server                       │      │     │
│  │  │  ├─ Scrapes metrics from:                │      │     │
│  │  │  │  ├─ Kubernetes API                    │      │     │
│  │  │  │  ├─ Node Exporter (node metrics)      │      │     │
│  │  │  │  ├─ kube-state-metrics (K8s objects)  │      │     │
│  │  │  │  └─ Application pods (/metrics)       │      │     │
│  │  │  ├─ Storage: Persistent Volume (50Gi)    │      │     │
│  │  │  └─ Retention: 15 days                   │      │     │
│  │  └──────────────────────────────────────────┘      │     │
│  │                                                     │     │
│  │  ┌──────────────────────────────────────────┐      │     │
│  │  │  Grafana                                 │      │     │
│  │  │  ├─ Dashboards: Pre-configured           │      │     │
│  │  │  ├─ Data Source: Prometheus              │      │     │
│  │  │  ├─ Access: LoadBalancer / Ingress       │      │     │
│  │  │  └─ Auth: Admin user                     │      │     │
│  │  └──────────────────────────────────────────┘      │     │
│  │                                                     │     │
│  │  ┌──────────────────────────────────────────┐      │     │
│  │  │  Alertmanager                            │      │     │
│  │  │  ├─ Alerts: CPU, Memory, Disk, Pod       │      │     │
│  │  │  ├─ Notifications: Email, Slack, PagerDuty│     │     │
│  │  │  └─ Rules: Configurable                  │      │     │
│  │  └──────────────────────────────────────────┘      │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Your Application (flask-app)                      │     │
│  │  └─ Exposes /metrics endpoint (optional)           │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Step-by-Step: Install Prometheus + Grafana

### **Step 1: Add Helm Repository**

```bash
# Add Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Verify repo added
helm search repo prometheus-community
```

### **Step 2: Create Namespace**

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Verify namespace
kubectl get namespaces
```

### **Step 3: Create Values File**

Create `prometheus-values.yaml`:

```yaml
# prometheus-values.yaml
# Configuration for kube-prometheus-stack

# Prometheus Configuration
prometheus:
  prometheusSpec:
    # Retention period for metrics
    retention: 15d
    
    # Storage for Prometheus data
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    
    # Resource limits
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 1000m
        memory: 4Gi
    
    # Service Monitor selector (scrape all)
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

# Grafana Configuration
grafana:
  enabled: true
  
  # Admin credentials
  adminPassword: "YourSecurePassword123!"  # CHANGE THIS!
  
  # Persistence for Grafana data
  persistence:
    enabled: true
    storageClassName: gp2
    size: 10Gi
  
  # Service type (LoadBalancer for external access)
  service:
    type: LoadBalancer
    # Or use ClusterIP and create Ingress
    # type: ClusterIP
  
  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  # Pre-installed dashboards
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  
  # Default dashboards
  dashboards:
    default:
      # Kubernetes cluster monitoring
      kubernetes-cluster:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      
      # Node exporter
      node-exporter:
        gnetId: 1860
        revision: 27
        datasource: Prometheus
      
      # Pod monitoring
      kubernetes-pods:
        gnetId: 6417
        revision: 1
        datasource: Prometheus

# Alertmanager Configuration
alertmanager:
  enabled: true
  
  # Persistence
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
  
  # Alert configuration
  config:
    global:
      resolve_timeout: 5m
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
    
    receivers:
    - name: 'default'
      # Add email, Slack, or other receivers here
      # email_configs:
      # - to: 'your-email@example.com'
      #   from: 'alertmanager@example.com'
      #   smarthost: 'smtp.gmail.com:587'
      #   auth_username: 'your-email@example.com'
      #   auth_password: 'your-app-password'

# Node Exporter (collects node metrics)
nodeExporter:
  enabled: true

# Kube State Metrics (collects K8s object metrics)
kubeStateMetrics:
  enabled: true

# Prometheus Operator
prometheusOperator:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

### **Step 4: Install Prometheus Stack**

```bash
# Install using Helm
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --version 55.0.0

# Wait for all pods to be ready
kubectl get pods -n monitoring -w

# Expected pods:
# - prometheus-stack-kube-prom-operator
# - prometheus-stack-kube-state-metrics
# - prometheus-stack-prometheus-node-exporter (on each node)
# - prometheus-stack-grafana
# - alertmanager-prometheus-stack-kube-prom-alertmanager
# - prometheus-prometheus-stack-kube-prom-prometheus
```

### **Step 5: Access Grafana**

#### **Option A: Via LoadBalancer (Easiest)**

```bash
# Get Grafana LoadBalancer URL
kubectl get svc -n monitoring prometheus-stack-grafana

# Output will show EXTERNAL-IP (LoadBalancer DNS)
# Example: a1b2c3d4e5f6.us-east-1.elb.amazonaws.com

# Access Grafana
# URL: http://<EXTERNAL-IP>
# Username: admin
# Password: YourSecurePassword123! (from values file)
```

#### **Option B: Via Port Forward (Testing)**

```bash
# Forward Grafana port to localhost
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Access Grafana
# URL: http://localhost:3000
# Username: admin
# Password: YourSecurePassword123!
```

#### **Option C: Via Ingress (Production)**

Create `grafana-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/group.name: monitoring
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-stack-grafana
            port:
              number: 80
```

Apply:
```bash
kubectl apply -f grafana-ingress.yaml

# Get ALB URL
kubectl get ingress -n monitoring grafana-ingress
```

### **Step 6: Configure Grafana Dashboards**

Once logged into Grafana:

1. **Verify Data Source:**
   - Go to: Configuration → Data Sources
   - Should see "Prometheus" already configured
   - Test connection

2. **Import Pre-built Dashboards:**
   - Go to: Dashboards → Browse
   - Should see pre-installed dashboards:
     - Kubernetes Cluster Monitoring
     - Node Exporter Full
     - Kubernetes Pods

3. **Import Additional Dashboards:**
   - Go to: Dashboards → Import
   - Enter dashboard ID from https://grafana.com/grafana/dashboards/
   
   **Recommended Dashboard IDs:**
   ```
   7249  - Kubernetes Cluster Monitoring
   1860  - Node Exporter Full
   6417  - Kubernetes Pods Monitoring
   315   - Kubernetes Cluster Monitoring (Prometheus)
   8588  - Kubernetes Deployment Statefulset Daemonset metrics
   13332 - Kubernetes / Views / Pods
   ```

4. **Create Custom Dashboard for Flask App:**
   - Click "+" → Dashboard
   - Add Panel
   - Query examples:
     ```promql
     # CPU usage of flask-app pods
     rate(container_cpu_usage_seconds_total{pod=~"flask-app.*"}[5m])
     
     # Memory usage of flask-app pods
     container_memory_usage_bytes{pod=~"flask-app.*"}
     
     # HTTP requests (if /metrics endpoint exists)
     rate(flask_http_requests_total[5m])
     
     # Pod restart count
     kube_pod_container_status_restarts_total{pod=~"flask-app.*"}
     ```

### **Step 7: Access Prometheus UI**

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Access Prometheus UI
# URL: http://localhost:9090

# Test queries:
# - up (shows all targets)
# - node_cpu_seconds_total
# - kube_pod_info
```

### **Step 8: Configure Alerts**

Create `flask-app-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: flask-app-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus-stack-prometheus
    role: alert-rules
spec:
  groups:
  - name: flask-app
    interval: 30s
    rules:
    
    # Alert if flask-app pod is down
    - alert: FlaskAppDown
      expr: up{job="flask-app"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Flask app is down"
        description: "Flask app pod {{ $labels.pod }} has been down for more than 5 minutes"
    
    # Alert if pod restarts frequently
    - alert: FlaskAppHighRestarts
      expr: rate(kube_pod_container_status_restarts_total{pod=~"flask-app.*"}[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Flask app pod restarting frequently"
        description: "Pod {{ $labels.pod }} has restarted {{ $value }} times in the last 15 minutes"
    
    # Alert if CPU usage is high
    - alert: FlaskAppHighCPU
      expr: rate(container_cpu_usage_seconds_total{pod=~"flask-app.*"}[5m]) > 0.8
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Flask app high CPU usage"
        description: "Pod {{ $labels.pod }} CPU usage is above 80% for more than 10 minutes"
    
    # Alert if memory usage is high
    - alert: FlaskAppHighMemory
      expr: container_memory_usage_bytes{pod=~"flask-app.*"} / container_spec_memory_limit_bytes{pod=~"flask-app.*"} > 0.9
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Flask app high memory usage"
        description: "Pod {{ $labels.pod }} memory usage is above 90% for more than 10 minutes"
    
    # Alert if no healthy pods
    - alert: FlaskAppNoHealthyPods
      expr: sum(kube_pod_status_phase{pod=~"flask-app.*",phase="Running"}) == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "No healthy Flask app pods"
        description: "All Flask app pods are unhealthy or not running"
```

Apply:
```bash
kubectl apply -f flask-app-alerts.yaml

# Verify alerts are loaded
kubectl get prometheusrules -n monitoring
```

### **Step 9: Add Flask App Metrics (Optional)**

To expose custom metrics from your Flask app, add Prometheus client:

**Update `requirements.txt`:**
```txt
Flask==3.0.0
flask-sqlalchemy==3.1.1
flask-migrate==4.0.5
Pillow==10.1.0
python-dotenv==1.0.0
prometheus-flask-exporter==0.23.0  # Add this
```

**Update `app.py`:**
```python
from flask import Flask, request, jsonify, render_template, redirect, url_for, flash, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from werkzeug.utils import secure_filename
import os
from datetime import datetime
from PIL import Image
import uuid

# Add Prometheus metrics
from prometheus_flask_exporter import PrometheusMetrics

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

app = Flask(__name__)

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)

# Add custom metrics
metrics.info('flask_app_info', 'Application info', version='1.0.0')

# ... rest of your app.py code ...
```

**Create ServiceMonitor:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: flask-app-metrics
  namespace: default
  labels:
    app: flask-app
spec:
  selector:
    matchLabels:
      app: flask-app
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

---

## 🐮 Option 2: Rancher Integration

### **Why Rancher?**
- ✅ Multi-cluster management
- ✅ Built-in monitoring (Prometheus + Grafana)
- ✅ User-friendly UI
- ✅ RBAC and authentication
- ❌ More complex setup
- ❌ Requires dedicated Rancher server

### **Architecture:**
```
┌─────────────────────────────────────────────────────────────┐
│              Rancher Server (Separate Cluster)               │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Rancher Management UI                             │     │
│  │  ├─ Multi-cluster dashboard                        │     │
│  │  ├─ User management                                │     │
│  │  ├─ RBAC                                           │     │
│  │  └─ Monitoring configuration                       │     │
│  └────────────────────────────────────────────────────┘     │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           │ Manages
                           ↓
┌─────────────────────────────────────────────────────────────┐
│              EKS Cluster (flask-eks)                         │
│              (Imported into Rancher)                         │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Rancher Agent                                     │     │
│  │  └─ Communicates with Rancher server              │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Rancher Monitoring (Prometheus + Grafana)         │     │
│  │  └─ Installed via Rancher UI                      │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### **Step 1: Install Rancher Server**

**Option A: On Existing Kubernetes Cluster**

```bash
# Add Rancher Helm repo
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update

# Create namespace
kubectl create namespace cattle-system

# Install cert-manager (required)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager
kubectl get pods -n cert-manager -w

# Install Rancher
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.yourdomain.com \
  --set replicas=1 \
  --set bootstrapPassword=admin

# Wait for Rancher to be ready
kubectl -n cattle-system rollout status deploy/rancher

# Get Rancher URL
kubectl get ingress -n cattle-system
```

**Option B: Docker (Single Node - Testing Only)**

```bash
docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest
```

### **Step 2: Access Rancher UI**

```bash
# Get Rancher URL
echo https://rancher.yourdomain.com

# Or if using Docker
echo https://localhost

# Initial login:
# Username: admin
# Password: (bootstrap password or set new one)
```

### **Step 3: Import EKS Cluster**

1. **In Rancher UI:**
   - Click "☰" → Cluster Management
   - Click "Import Existing"
   - Select "Generic" (for EKS)
   - Enter cluster name: `flask-eks`
   - Click "Create"

2. **Run Import Command:**
   ```bash
   # Rancher will provide a kubectl command like:
   kubectl apply -f https://rancher.yourdomain.com/v3/import/xxxxx.yaml
   
   # Run this command on your local machine (with kubeconfig for flask-eks)
   ```

3. **Wait for Import:**
   - Cluster will appear in Rancher UI
   - Status will change to "Active"

### **Step 4: Enable Monitoring in Rancher**

1. **In Rancher UI:**
   - Select your cluster (flask-eks)
   - Click "Cluster Tools" (bottom left)
   - Find "Monitoring" card
   - Click "Install"

2. **Configure Monitoring:**
   ```yaml
   # Prometheus settings
   prometheus:
     retention: 15d
     storageSize: 50Gi
   
   # Grafana settings
   grafana:
     enabled: true
     storageSize: 10Gi
   
   # Node exporter
   nodeExporter:
     enabled: true
   ```

3. **Click "Install"**
   - Wait 5-10 minutes for installation

### **Step 5: Access Grafana via Rancher**

1. **In Rancher UI:**
   - Select cluster → Monitoring
   - Click "Grafana" icon
   - Grafana opens in new tab
   - Pre-configured dashboards available

### **Step 6: Configure Alerts in Rancher**

1. **In Rancher UI:**
   - Cluster → Monitoring → Alerting
   - Click "Create Receiver"
   - Configure: Email, Slack, PagerDuty, etc.
   - Create alert rules

---

## ☁️ Option 3: AWS Native Monitoring

### **Why AWS CloudWatch?**
- ✅ Native AWS integration
- ✅ Simple setup
- ✅ No infrastructure to manage
- ✅ Container Insights for EKS
- ❌ Limited customization
- ❌ Pay-per-use pricing

### **Step 1: Enable Container Insights**

```bash
# Install CloudWatch agent
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml

# Verify installation
kubectl get pods -n amazon-cloudwatch
```

### **Step 2: Create IAM Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Step 3: Attach Policy to Node Role**

```bash
# Get node IAM role
aws eks describe-nodegroup \
  --cluster-name flask-eks \
  --nodegroup-name <nodegroup-name> \
  --query "nodegroup.nodeRole" \
  --output text

# Attach policy
aws iam attach-role-policy \
  --role-name <node-role-name> \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

### **Step 4: View Metrics in CloudWatch**

1. **AWS Console:**
   - Go to CloudWatch
   - Click "Container Insights"
   - Select cluster: flask-eks
   - View dashboards:
     - Cluster performance
     - Node performance
     - Pod performance
     - Service performance

2. **Create Custom Dashboards:**
   - CloudWatch → Dashboards → Create
   - Add widgets for:
     - CPU utilization
     - Memory utilization
     - Network I/O
     - Disk I/O

### **Step 5: Set Up Alarms**

```bash
# Example: CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name flask-app-high-cpu \
  --alarm-description "Alert when flask-app CPU > 80%" \
  --metric-name pod_cpu_utilization \
  --namespace ContainerInsights \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=ClusterName,Value=flask-eks Name=PodName,Value=flask-app-*
```

---

## 📊 Comparison Matrix

| Feature | Prometheus + Grafana | Rancher | AWS CloudWatch |
|---------|---------------------|---------|----------------|
| **Cost** | Free (self-hosted) | Free (self-hosted) | Pay-per-use |
| **Setup Complexity** | Medium | High | Low |
| **Customization** | High | Medium | Low |
| **Multi-cluster** | Manual | Built-in | Manual |
| **Dashboards** | Extensive | Pre-built | Limited |
| **Alerting** | Flexible | Built-in | Basic |
| **Storage** | Self-managed | Self-managed | Managed |
| **Retention** | Configurable | Configurable | 15 months max |
| **Learning Curve** | Medium | Medium | Low |
| **Community** | Large | Medium | AWS docs |
| **Best For** | K8s experts | Multi-cluster mgmt | AWS-first orgs |

---

## 🎯 Recommended Setup for Your Project

### **Phase 1: Quick Start (Now)**
```bash
# Install Prometheus + Grafana
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword='YourPassword123!'

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Login: admin / YourPassword123!
```

### **Phase 2: Production Setup (Later)**
1. Configure persistent storage
2. Set up Ingress with TLS
3. Configure alerting (email/Slack)
4. Add custom dashboards
5. Enable authentication (OAuth/LDAP)

### **Phase 3: Advanced (Optional)**
1. Add Rancher for multi-cluster management
2. Integrate with AWS CloudWatch for hybrid monitoring
3. Set up log aggregation (Loki)
4. Add distributed tracing (Jaeger/Tempo)

---

## 🔧 Quick Commands Reference

### **Prometheus + Grafana**
```bash
# Install
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# Upgrade
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring

# Uninstall
helm uninstall prometheus-stack -n monitoring

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# View pods
kubectl get pods -n monitoring

# View services
kubectl get svc -n monitoring

# View logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### **Rancher**
```bash
# Install Rancher
helm install rancher rancher-latest/rancher --namespace cattle-system --create-namespace

# Get Rancher URL
kubectl get ingress -n cattle-system

# Uninstall
helm uninstall rancher -n cattle-system
```

### **CloudWatch**
```bash
# Install Container Insights
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml

# Check status
kubectl get pods -n amazon-cloudwatch

# View logs
kubectl logs -n amazon-cloudwatch -l name=cloudwatch-agent
```

---

## 🐛 Troubleshooting

### **Issue 1: Prometheus Not Scraping Metrics**

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
# Open: http://localhost:9090/targets

# Check ServiceMonitor
kubectl get servicemonitor -n monitoring

# Check if service has correct labels
kubectl get svc -n default flask-svc -o yaml
```

### **Issue 2: Grafana Can't Connect to Prometheus**

```bash
# Check Prometheus service
kubectl get svc -n monitoring | grep prometheus

# Check Grafana data source
kubectl exec -n monitoring deployment/prometheus-stack-grafana -- \
  curl -s http://prometheus-stack-kube-prom-prometheus:9090/api/v1/status/config
```

### **Issue 3: Out of Storage**

```bash
# Check PVC usage
kubectl get pvc -n monitoring

# Increase storage
kubectl edit pvc prometheus-prometheus-stack-kube-prom-prometheus-db-prometheus-prometheus-stack-kube-prom-prometheus-0 -n monitoring

# Or reduce retention
kubectl edit prometheus -n monitoring prometheus-stack-kube-prom-prometheus
# Change: retention: 7d
```

### **Issue 4: High Memory Usage**

```bash
# Reduce scrape interval
kubectl edit prometheus -n monitoring prometheus-stack-kube-prom-prometheus
# Add: scrapeInterval: 60s (default: 30s)

# Reduce retention
# Change: retention: 7d (default: 15d)
```

---

## 📚 Additional Resources

### **Documentation:**
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Rancher Docs](https://rancher.com/docs/)
- [AWS Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)

### **Grafana Dashboards:**
- [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)
- [Kubernetes Dashboards](https://grafana.com/grafana/dashboards/?search=kubernetes)

### **PromQL (Prometheus Query Language):**
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [PromQL Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)

---

## 🎯 Next Steps

1. **Install Prometheus + Grafana** (Recommended first step)
   ```bash
   helm install prometheus-stack prometheus-community/kube-prometheus-stack \
     --namespace monitoring --create-namespace
   ```

2. **Access Grafana and explore dashboards**
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
   ```

3. **Configure alerts for your Flask app**

4. **Add custom metrics to your application** (optional)

5. **Set up Ingress for production access**

---

**Guide Created:** October 9, 2025  
**For Cluster:** flask-eks (us-east-1)  
**Status:** Ready to implement
