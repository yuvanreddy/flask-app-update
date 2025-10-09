# Alerts and Notifications Guide

**Cluster:** flask-eks  
**Alertmanager:** Installed with Prometheus Stack  
**Date:** October 9, 2025

---

## 📋 Table of Contents

1. [View Configured Alerts](#view-configured-alerts)
2. [Access Alertmanager UI](#access-alertmanager-ui)
3. [Check Alert Status](#check-alert-status)
4. [Configure Email Notifications](#configure-email-notifications)
5. [Configure Slack Notifications](#configure-slack-notifications)
6. [Configure Other Notification Channels](#configure-other-notification-channels)
7. [Test Alerts](#test-alerts)
8. [Troubleshooting](#troubleshooting)

---

## 🔍 Step 1: View Configured Alerts

### **Method 1: Using kubectl**

```powershell
# List all PrometheusRules (alert definitions)
kubectl get prometheusrules -n monitoring

# View Flask app alerts specifically
kubectl get prometheusrules -n monitoring flask-app-alerts -o yaml

# View all alert rules
kubectl get prometheusrules -n monitoring -o wide
```

### **Method 2: View in Prometheus UI**

```powershell
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

Then open browser to: **http://localhost:9090**

1. Click **"Alerts"** in the top menu
2. You'll see all configured alerts with their status:
   - 🟢 **Inactive** - Alert condition not met
   - 🟡 **Pending** - Alert condition met, waiting for duration
   - 🔴 **Firing** - Alert is active

### **Your Flask App Alerts:**

You should see these alerts:
```
1. FlaskAppPodDown - Pod is down for >5 minutes
2. FlaskAppNoPodsRunning - No pods running for >3 minutes
3. FlaskAppHighRestartRate - Frequent restarts
4. FlaskAppHighCPUUsage - CPU >80% for >10 minutes
5. FlaskAppHighMemoryUsage - Memory >90% for >10 minutes
6. FlaskAppCPUThrottling - CPU throttled
7. FlaskAppPVCAlmostFull - Storage >85%
8. FlaskAppPVCCriticallyFull - Storage >95%
9. FlaskAppServiceNoEndpoints - Service has no endpoints
10. FlaskAppDatabasePVCIssue - Database PVC not bound
```

---

## 🚨 Step 2: Access Alertmanager UI

Alertmanager manages alert routing and notifications.

### **Method 1: Port Forward (Easiest)**

```powershell
# Port forward Alertmanager
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093
```

Then open browser to: **http://localhost:9093**

### **Method 2: Create LoadBalancer Service**

```powershell
# Create LoadBalancer for Alertmanager
kubectl patch svc prometheus-stack-kube-prom-alertmanager -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'

# Get external URL
kubectl get svc -n monitoring prometheus-stack-kube-prom-alertmanager
```

### **Method 3: Create Ingress**

Create file `alertmanager-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager-ingress
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
            name: prometheus-stack-kube-prom-alertmanager
            port:
              number: 9093
```

Apply:
```powershell
kubectl apply -f alertmanager-ingress.yaml
kubectl get ingress -n monitoring alertmanager-ingress
```

---

## 📊 Step 3: Check Alert Status

### **In Alertmanager UI:**

Once you access Alertmanager (http://localhost:9093):

1. **Main Page** - Shows active alerts
   - 🔴 **Firing** - Currently active alerts
   - 🔕 **Silenced** - Alerts that are muted

2. **Alerts Tab** - View all alerts
   - Filter by: Label, State, Receiver
   - Search for specific alerts

3. **Silences Tab** - Manage alert silences
   - Create temporary silences
   - View active silences

4. **Status Tab** - Alertmanager configuration
   - View routing tree
   - Check receivers

### **Check Active Alerts:**

```powershell
# Query Prometheus for active alerts
kubectl exec -n monitoring prometheus-prometheus-stack-kube-prom-prometheus-0 -c prometheus -- wget -qO- http://localhost:9090/api/v1/alerts | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty alerts
```

### **Check Alert History in Grafana:**

1. Open Grafana
2. Go to **Alerting** → **Alert rules**
3. You'll see all configured alerts with their status

---

## 📧 Step 4: Configure Email Notifications

### **Step 4.1: Update Alertmanager Configuration**

Edit your `prometheus-values.yaml`:

```yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
      # SMTP Configuration
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alertmanager@yourdomain.com'
      smtp_auth_username: 'your-email@gmail.com'
      smtp_auth_password: 'your-app-password'  # Use App Password, not regular password
      smtp_require_tls: true
    
    # Routing
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'default'
      routes:
      - match:
          severity: critical
        receiver: 'critical-email'
        continue: true
      - match:
          severity: warning
        receiver: 'warning-email'
    
    # Receivers
    receivers:
    - name: 'default'
      email_configs:
      - to: 'team@yourdomain.com'
        headers:
          Subject: '[ALERT] {{ .GroupLabels.alertname }}'
    
    - name: 'critical-email'
      email_configs:
      - to: 'oncall@yourdomain.com'
        headers:
          Subject: '[CRITICAL] {{ .GroupLabels.alertname }} - Immediate Action Required'
        html: |
          <h2>Critical Alert</h2>
          <p><strong>Alert:</strong> {{ .GroupLabels.alertname }}</p>
          <p><strong>Severity:</strong> {{ .CommonLabels.severity }}</p>
          <p><strong>Description:</strong> {{ range .Alerts }}{{ .Annotations.description }}{{ end }}</p>
          <p><strong>Time:</strong> {{ .CommonAnnotations.timestamp }}</p>
    
    - name: 'warning-email'
      email_configs:
      - to: 'alerts@yourdomain.com'
        headers:
          Subject: '[WARNING] {{ .GroupLabels.alertname }}'
```

### **Step 4.2: Get Gmail App Password**

If using Gmail:

1. Go to: https://myaccount.google.com/apppasswords
2. Select app: **Mail**
3. Select device: **Other (Custom name)** → "Alertmanager"
4. Click **Generate**
5. Copy the 16-character password
6. Use this in `smtp_auth_password`

### **Step 4.3: Apply Configuration**

```powershell
# Upgrade Helm release with new configuration
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --values prometheus-values.yaml

# Wait for Alertmanager to restart
kubectl rollout status statefulset -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager
```

### **Step 4.4: Test Email Notification**

```powershell
# Port forward Alertmanager
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093

# Send test alert via API
$body = @{
    alerts = @(
        @{
            labels = @{
                alertname = "TestAlert"
                severity = "warning"
            }
            annotations = @{
                summary = "This is a test alert"
                description = "Testing email notifications"
            }
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:9093/api/v1/alerts" -Method Post -Body $body -ContentType "application/json"
```

Check your email - you should receive a test alert!

---

## 💬 Step 5: Configure Slack Notifications

### **Step 5.1: Create Slack Webhook**

1. Go to: https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. Name: "Alertmanager"
4. Select your workspace
5. Click **"Incoming Webhooks"** → Enable
6. Click **"Add New Webhook to Workspace"**
7. Select channel (e.g., #alerts)
8. Copy the webhook URL (looks like: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX`)

### **Step 5.2: Update Alertmanager Configuration**

Edit `prometheus-values.yaml`:

```yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
      slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack-notifications'
      routes:
      - match:
          severity: critical
        receiver: 'slack-critical'
      - match:
          severity: warning
        receiver: 'slack-warnings'
    
    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts'
        title: 'Alert: {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Severity:* {{ .Labels.severity }}
          *Description:* {{ .Annotations.description }}
          *Pod:* {{ .Labels.pod }}
          {{ end }}
        send_resolved: true
    
    - name: 'slack-critical'
      slack_configs:
      - channel: '#alerts-critical'
        title: ':fire: CRITICAL ALERT: {{ .GroupLabels.alertname }}'
        text: |
          <!channel> Immediate action required!
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Severity:* {{ .Labels.severity }}
          *Description:* {{ .Annotations.description }}
          *Pod:* {{ .Labels.pod }}
          *Time:* {{ .StartsAt }}
          {{ end }}
        send_resolved: true
        color: 'danger'
    
    - name: 'slack-warnings'
      slack_configs:
      - channel: '#alerts'
        title: ':warning: Warning: {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Description:* {{ .Annotations.description }}
          {{ end }}
        send_resolved: true
        color: 'warning'
```

### **Step 5.3: Apply and Test**

```powershell
# Apply configuration
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --values prometheus-values.yaml

# Test Slack notification
$body = @{
    alerts = @(
        @{
            labels = @{
                alertname = "TestSlackAlert"
                severity = "warning"
                pod = "flask-app-test"
            }
            annotations = @{
                summary = "Slack notification test"
                description = "Testing Slack integration"
            }
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:9093/api/v1/alerts" -Method Post -Body $body -ContentType "application/json"
```

Check your Slack channel!

---

## 🔔 Step 6: Configure Other Notification Channels

### **PagerDuty**

```yaml
receivers:
- name: 'pagerduty'
  pagerduty_configs:
  - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
    description: '{{ .GroupLabels.alertname }}: {{ .CommonAnnotations.description }}'
```

### **Microsoft Teams**

```yaml
receivers:
- name: 'teams'
  webhook_configs:
  - url: 'YOUR_TEAMS_WEBHOOK_URL'
    send_resolved: true
```

### **Discord**

```yaml
receivers:
- name: 'discord'
  webhook_configs:
  - url: 'YOUR_DISCORD_WEBHOOK_URL'
    send_resolved: true
```

### **OpsGenie**

```yaml
receivers:
- name: 'opsgenie'
  opsgenie_configs:
  - api_key: 'YOUR_OPSGENIE_API_KEY'
    message: '{{ .GroupLabels.alertname }}'
    description: '{{ .CommonAnnotations.description }}'
```

---

## 🧪 Step 7: Test Alerts

### **Test 1: Trigger CPU Alert (Manual)**

```powershell
# Access pod and run CPU stress
kubectl exec -it flask-app-65fbfd86bb-94pln -n default -- python -c "import time; end = time.time() + 900; [sum(i*i for i in range(100000)) for _ in iter(lambda: time.time() < end, False)]"

# This runs for 15 minutes
# Alert should fire after 10 minutes of high CPU
```

### **Test 2: Trigger Pod Down Alert**

```powershell
# Scale deployment to 0 replicas
kubectl scale deployment flask-app -n default --replicas=0

# Wait 5 minutes
# Alert "FlaskAppNoPodsRunning" should fire

# Scale back up
kubectl scale deployment flask-app -n default --replicas=1
```

### **Test 3: Send Test Alert via API**

```powershell
# Port forward Alertmanager
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093

# Send test alert
$testAlert = @{
    alerts = @(
        @{
            labels = @{
                alertname = "FlaskAppHighCPUUsage"
                severity = "warning"
                pod = "flask-app-65fbfd86bb-94pln"
                namespace = "default"
            }
            annotations = @{
                summary = "Flask app high CPU usage"
                description = "Pod flask-app-65fbfd86bb-94pln CPU usage is above 80%"
            }
            startsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:9093/api/v1/alerts" -Method Post -Body $testAlert -ContentType "application/json"
```

### **Test 4: Check Alert in Alertmanager UI**

1. Open: http://localhost:9093
2. You should see the test alert
3. Check if notification was sent (email/Slack)

---

## 🔍 Step 8: View Alert History

### **In Grafana:**

1. Login to Grafana
2. Go to **Alerting** → **Alert rules**
3. Click on any alert to see:
   - Current state
   - History
   - Evaluation results

### **In Prometheus:**

1. Open: http://localhost:9090
2. Click **"Alerts"**
3. See all alerts with their status

### **Query Alert Metrics:**

```promql
# Count firing alerts
count(ALERTS{alertstate="firing"})

# Show all firing alerts
ALERTS{alertstate="firing"}

# Flask app specific alerts
ALERTS{alertname=~"FlaskApp.*"}

# Critical alerts only
ALERTS{severity="critical",alertstate="firing"}
```

---

## 🛠️ Step 9: Troubleshooting

### **Issue 1: Alerts Not Firing**

**Check alert rules are loaded:**
```powershell
kubectl get prometheusrules -n monitoring flask-app-alerts

# View rule details
kubectl describe prometheusrules -n monitoring flask-app-alerts
```

**Check Prometheus can evaluate rules:**
```powershell
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Open: http://localhost:9090/rules
# Verify your alerts are listed
```

**Check alert query returns data:**
```powershell
# In Prometheus UI, run the alert query manually
# Example:
sum(rate(container_cpu_usage_seconds_total{pod=~"flask-app.*"}[5m])) > 0.8
```

### **Issue 2: Notifications Not Sent**

**Check Alertmanager configuration:**
```powershell
# View Alertmanager config
kubectl get secret -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Check Alertmanager logs:**
```powershell
kubectl logs -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -c alertmanager --tail=100
```

**Test SMTP connection:**
```powershell
# Access Alertmanager pod
kubectl exec -it -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -c alertmanager -- /bin/sh

# Test SMTP (if telnet available)
telnet smtp.gmail.com 587
```

### **Issue 3: Too Many Alerts**

**Silence alerts temporarily:**

In Alertmanager UI (http://localhost:9093):
1. Click **"Silences"** tab
2. Click **"New Silence"**
3. Add matchers:
   - `alertname = FlaskAppHighCPUUsage`
4. Set duration: 2 hours
5. Add comment: "Maintenance window"
6. Click **"Create"**

**Or via API:**
```powershell
$silence = @{
    matchers = @(
        @{
            name = "alertname"
            value = "FlaskAppHighCPUUsage"
            isRegex = $false
        }
    )
    startsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    endsAt = (Get-Date).AddHours(2).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    createdBy = "admin"
    comment = "Maintenance window"
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:9093/api/v1/silences" -Method Post -Body $silence -ContentType "application/json"
```

---

## 📋 Quick Commands Reference

```powershell
# View all alert rules
kubectl get prometheusrules -n monitoring

# View Flask app alerts
kubectl get prometheusrules -n monitoring flask-app-alerts -o yaml

# Port forward Prometheus (view alerts)
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Port forward Alertmanager (manage notifications)
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093

# Check Alertmanager logs
kubectl logs -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0 -c alertmanager

# Restart Alertmanager
kubectl delete pod -n monitoring alertmanager-prometheus-stack-kube-prom-alertmanager-0

# Update alert configuration
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f prometheus-values.yaml
```

---

## ✅ Checklist

**Setup:**
- [ ] Alerts are configured (flask-app-alerts.yaml applied)
- [ ] Alertmanager is running
- [ ] Can access Alertmanager UI

**Notifications:**
- [ ] Email/Slack webhook configured
- [ ] Configuration applied via Helm
- [ ] Test notification sent successfully

**Testing:**
- [ ] Triggered test alert
- [ ] Received notification
- [ ] Alert appears in Alertmanager UI
- [ ] Alert resolves when condition clears

---

## 🎯 Next Steps

1. **Access Alertmanager now:**
   ```powershell
   kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093
   ```
   Open: http://localhost:9093

2. **Configure email or Slack** (choose one to start)

3. **Test with CPU stress** to trigger real alert

4. **Verify notification received**

---

**Created:** October 9, 2025  
**For:** Flask Photo Gallery Monitoring  
**Alertmanager Version:** v0.26.0
