# Grafana Dashboard Creation - Step-by-Step Guide

**Application:** Flask Photo Gallery  
**Grafana URL:** http://k8s-monitori-promethe-c617b8a740-e2d875751e5d49de.elb.us-east-1.amazonaws.com  
**Date:** October 9, 2025

---

## 📋 Table of Contents

1. [Access Grafana](#access-grafana)
2. [Import Pre-built Dashboards](#import-pre-built-dashboards)
3. [Create Custom Dashboard from Scratch](#create-custom-dashboard-from-scratch)
4. [Add Panels with Queries](#add-panels-with-queries)
5. [Panel Types and When to Use Them](#panel-types-and-when-to-use-them)
6. [Configure Panel Settings](#configure-panel-settings)
7. [Create Flask App Dashboard (Complete Example)](#create-flask-app-dashboard-complete-example)
8. [Save and Share Dashboards](#save-and-share-dashboards)
9. [Tips and Best Practices](#tips-and-best-practices)

---

## 🚀 Step 1: Access Grafana

### **Option A: Via LoadBalancer (Direct Access)**

1. **Open your browser**
2. **Navigate to:**
   ```
   http://k8s-monitori-promethe-c617b8a740-e2d875751e5d49de.elb.us-east-1.amazonaws.com
   ```

3. **Login:**
   - Username: `admin`
   - Password: `ChangeMe123!SecurePassword`

4. **Click "Sign in"**

### **Option B: Via Port Forward (Local Access)**

1. **Open PowerShell**
2. **Run port forward command:**
   ```powershell
   kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
   ```

3. **Open browser to:**
   ```
   http://localhost:3000
   ```

4. **Login with same credentials**

---

## 📥 Step 2: Import Pre-built Dashboards

### **Method 1: Import by Dashboard ID**

1. **Click the "+" icon** in the left sidebar
2. **Select "Import"**
3. **Enter Dashboard ID** (e.g., `7249` for Kubernetes Cluster)
4. **Click "Load"**
5. **Configure options:**
   - Name: (auto-filled, you can change)
   - Folder: Select "General" or create new folder
   - Prometheus: Select "Prometheus" from dropdown
6. **Click "Import"**

**Recommended Dashboard IDs:**
```
7249  - Kubernetes Cluster Monitoring
1860  - Node Exporter Full
6417  - Kubernetes Pods Monitoring
8588  - Kubernetes Deployment Statefulset Daemonset
13646 - Kubernetes Persistent Volumes
315   - Kubernetes Cluster (Prometheus)
```

### **Method 2: Import from JSON**

1. **Click "+" → Import**
2. **Click "Upload JSON file"**
3. **Select your JSON file**
4. **Click "Import"**

### **Method 3: Import from URL**

1. **Click "+" → Import**
2. **Paste Grafana.com URL** (e.g., `https://grafana.com/grafana/dashboards/7249`)
3. **Click "Load"**
4. **Click "Import"**

---

## 🎨 Step 3: Create Custom Dashboard from Scratch

### **Step 3.1: Create New Dashboard**

1. **Click the "+" icon** in left sidebar
2. **Select "Dashboard"**
3. You'll see an empty dashboard

### **Step 3.2: Add First Panel**

1. **Click "Add visualization"** button
2. **Select "Prometheus"** as data source
3. You'll see the panel editor

---

## 📊 Step 4: Add Panels with Queries

### **Step 4.1: Understanding the Panel Editor**

The panel editor has several sections:

```
┌─────────────────────────────────────────────────────────┐
│  Panel Title                                    [X] Close│
├─────────────────────────────────────────────────────────┤
│  [Visualization Preview Area]                           │
│  (Shows how your panel will look)                       │
│                                                          │
├─────────────────────────────────────────────────────────┤
│  Tabs: [Query] [Transform] [Alert] [Panel options]     │
│                                                          │
│  Query Section:                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Prometheus Query Editor                         │   │
│  │ [Code] [Builder]                                │   │
│  │                                                  │   │
│  │ Metric: [Select metric dropdown]                │   │
│  │ Query: [Enter PromQL query]                     │   │
│  │                                                  │   │
│  │ Legend: {{pod}}                                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### **Step 4.2: Add Your First Query (CPU Usage)**

1. **In the Query tab**, you'll see the query editor

2. **Click "Code" mode** (top right of query editor)

3. **Paste this query:**
   ```promql
   sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod) * 1000
   ```

4. **Set Legend:**
   - In "Legend" field, enter: `{{pod}}`
   - This will show pod name in the legend

5. **Click "Run queries"** button (or it auto-runs)

6. **You should see a graph** showing CPU usage

### **Step 4.3: Configure Visualization**

1. **Click "Panel options"** tab (right side)

2. **Set Panel Title:**
   - Title: `Flask App CPU Usage`
   - Description: `CPU usage in millicores`

3. **Click "Visualization"** dropdown (top right)
   - Select: `Time series` (for line graph)
   - Or: `Stat` (for single number)
   - Or: `Gauge` (for percentage)

4. **Configure Units:**
   - Scroll down to "Standard options"
   - Unit: Select "Misc" → "millicores" (or "short")
   - Decimals: 0

5. **Set Thresholds (optional):**
   - Scroll to "Thresholds"
   - Add threshold: 400 (warning - yellow)
   - Add threshold: 450 (critical - red)

6. **Click "Apply"** (top right) to save panel

### **Step 4.4: Add More Panels**

1. **Click "Add" → "Visualization"** (top right)
2. **Repeat steps 4.2-4.3** with different queries

---

## 🎯 Step 5: Panel Types and When to Use Them

### **1. Time Series (Line Graph)**
```
Use for: Trends over time
Examples: CPU usage, memory usage, network traffic
```

**How to configure:**
1. Select "Time series" visualization
2. Add query
3. Set legend to show pod name: `{{pod}}`
4. Configure line style, fill, points

**Best for:**
- CPU usage over time
- Memory usage trends
- Network I/O
- Disk I/O

### **2. Stat (Single Number)**
```
Use for: Current value
Examples: Pod count, restart count, uptime
```

**How to configure:**
1. Select "Stat" visualization
2. Add query
3. Set "Calculation" to "Last" (shows most recent value)
4. Configure text size, colors

**Best for:**
- Number of running pods
- Current restart count
- Current memory usage
- Storage used

### **3. Gauge (Percentage)**
```
Use for: Percentage values (0-100%)
Examples: CPU %, memory %, storage %
```

**How to configure:**
1. Select "Gauge" visualization
2. Add query that returns percentage
3. Set min: 0, max: 100
4. Configure thresholds (green < 70%, yellow < 90%, red >= 90%)

**Best for:**
- CPU usage percentage
- Memory usage percentage
- Storage usage percentage

### **4. Bar Gauge (Multiple Values)**
```
Use for: Comparing multiple values
Examples: Storage across PVCs, pods across nodes
```

**How to configure:**
1. Select "Bar gauge" visualization
2. Add query with `by (label)` to show multiple values
3. Set orientation (horizontal/vertical)

**Best for:**
- Storage usage per PVC
- CPU usage per pod
- Memory usage per container

### **5. Table**
```
Use for: Detailed data with multiple columns
Examples: Pod details, resource usage breakdown
```

**How to configure:**
1. Select "Table" visualization
2. Add multiple queries
3. Configure columns to show
4. Add column aliases

**Best for:**
- Pod status with multiple metrics
- Resource usage breakdown
- Detailed logs

### **6. Heatmap**
```
Use for: Distribution over time
Examples: Response time distribution, latency
```

**Best for:**
- Request latency distribution
- Error rate patterns

---

## ⚙️ Step 6: Configure Panel Settings

### **6.1: Panel Options**

**Title and Description:**
```
Title: Flask App CPU Usage
Description: CPU usage in millicores (1 core = 1000m)
```

**Transparent Background:**
- Toggle "Transparent" to make panel background transparent

**Links:**
- Add links to related dashboards or documentation

### **6.2: Standard Options**

**Unit:**
```
Common units:
- millicores (for CPU)
- bytes (for memory/storage)
- bytes/sec (for network)
- percent (0-100) (for percentages)
- short (for counts)
```

**Min/Max:**
```
Set minimum and maximum values for Y-axis
Example: Min: 0, Max: 500 (for CPU limit)
```

**Decimals:**
```
Number of decimal places to show
Example: 0 for whole numbers, 2 for precise values
```

**Display Name:**
```
Override legend name
Example: ${__field.labels.pod} to show pod name
```

### **6.3: Thresholds**

**Add Color-coded Thresholds:**

1. **Click "Thresholds"** section
2. **Add threshold values:**
   ```
   Base: Green (0-70%)
   70: Yellow (70-90%)
   90: Red (90-100%)
   ```

3. **Choose threshold mode:**
   - Absolute: Fixed values (e.g., 400m, 450m)
   - Percentage: Percentage of max (e.g., 70%, 90%)

### **6.4: Value Mappings**

**Map Values to Text:**

Example: Map pod status numbers to text
```
0 → "Not Running" (red)
1 → "Running" (green)
```

### **6.5: Overrides**

**Override Settings for Specific Series:**

Example: Make one pod's line thicker
```
Fields with name: flask-app-12345
→ Line width: 3
→ Color: Blue
```

---

## 🎨 Step 7: Create Flask App Dashboard (Complete Example)

Let's create a complete dashboard for your Flask Photo Gallery app.

### **Step 7.1: Create Dashboard**

1. **Click "+" → Dashboard**
2. **Click "Dashboard settings"** (gear icon, top right)
3. **Set name:** `Flask Photo Gallery - Monitoring`
4. **Set description:** `Monitoring dashboard for Flask Photo Gallery application`
5. **Add tags:** `flask`, `photo-gallery`, `production`
6. **Click "Save dashboard"**

### **Step 7.2: Add Row 1 - Overview**

1. **Click "Add" → "Row"**
2. **Name it:** `Overview`
3. **Click "Add" → "Visualization"**

**Panel 1: Running Pods**
```
Query:
count(kube_pod_status_phase{namespace="default",pod=~"flask-app.*",phase="Running"})

Visualization: Stat
Title: Running Pods
Unit: short
Color: Green if value = 1
```

**Panel 2: Pod Uptime**
```
Query:
(time() - kube_pod_start_time{namespace="default",pod=~"flask-app.*"}) / 3600

Visualization: Stat
Title: Uptime
Unit: hours (h)
Decimals: 1
```

**Panel 3: Restart Count**
```
Query:
sum(kube_pod_container_status_restarts_total{namespace="default",pod=~"flask-app.*"})

Visualization: Stat
Title: Restarts
Unit: short
Thresholds: 0=green, 1=yellow, 3=red
```

**Panel 4: Memory Usage**
```
Query:
sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) / 1024 / 1024

Visualization: Stat
Title: Memory Usage
Unit: MB
Decimals: 0
```

### **Step 7.3: Add Row 2 - Resource Usage**

1. **Click "Add" → "Row"**
2. **Name it:** `Resource Usage`

**Panel 5: CPU Usage Over Time**
```
Query:
sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod) * 1000

Visualization: Time series
Title: CPU Usage (millicores)
Unit: millicores
Legend: {{pod}}
Thresholds: 400=yellow, 450=red
```

**Panel 6: Memory Usage Over Time**
```
Query:
sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod) / 1024 / 1024

Visualization: Time series
Title: Memory Usage (MB)
Unit: MB
Legend: {{pod}}
Thresholds: 400=yellow, 460=red
```

**Panel 7: CPU Usage Percentage**
```
Query:
(sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) / sum(kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"})) * 100

Visualization: Gauge
Title: CPU Usage (% of Limit)
Unit: percent (0-100)
Min: 0, Max: 100
Thresholds: 70=yellow, 90=red
```

**Panel 8: Memory Usage Percentage**
```
Query:
(sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) / sum(kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"})) * 100

Visualization: Gauge
Title: Memory Usage (% of Limit)
Unit: percent (0-100)
Min: 0, Max: 100
Thresholds: 70=yellow, 90=red
```

### **Step 7.4: Add Row 3 - Network**

**Panel 9: Network I/O**
```
Query A (Received):
sum(rate(container_network_receive_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod) / 1024

Query B (Transmitted):
sum(rate(container_network_transmit_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod) / 1024

Visualization: Time series
Title: Network I/O (KB/s)
Unit: KBps
Legend: {{pod}} - {{__name__}}
```

### **Step 7.5: Add Row 4 - Storage**

**Panel 10: Storage Usage**
```
Query A (Photos):
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"} / 1024 / 1024 / 1024

Query B (Thumbnails):
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-thumbnails-pvc"} / 1024 / 1024

Query C (Database):
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-db-pvc"} / 1024 / 1024

Visualization: Bar gauge
Title: Storage Usage
Unit: GB (for photos), MB (for others)
Orientation: Horizontal
```

**Panel 11: Storage Usage Percentage**
```
Query:
(kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim=~"flask-app.*"} / kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim=~"flask-app.*"}) * 100

Visualization: Gauge
Title: Storage Usage (%)
Unit: percent (0-100)
Thresholds: 70=yellow, 85=red
```

### **Step 7.6: Arrange Panels**

1. **Drag panels** to arrange them in a grid
2. **Resize panels** by dragging corners
3. **Recommended layout:**
   ```
   Row 1 (Overview): 4 stat panels side by side
   Row 2 (Resources): 2 graphs + 2 gauges
   Row 3 (Network): 1 full-width graph
   Row 4 (Storage): 1 bar gauge + 1 gauge
   ```

### **Step 7.7: Save Dashboard**

1. **Click "Save dashboard"** (disk icon, top right)
2. **Add description:** "Initial version with all metrics"
3. **Click "Save"**

---

## 💾 Step 8: Save and Share Dashboards

### **8.1: Save Dashboard**

1. **Click "Save dashboard"** icon (top right)
2. **Add save message:** "Added CPU and memory panels"
3. **Click "Save"**

### **8.2: Export Dashboard**

1. **Click "Dashboard settings"** (gear icon)
2. **Click "JSON Model"** (left sidebar)
3. **Click "Copy to Clipboard"**
4. **Save to file:** `flask-app-dashboard.json`

### **8.3: Share Dashboard**

**Option A: Share Link**
1. **Click "Share"** icon (top right)
2. **Copy link**
3. **Share with team**

**Option B: Create Snapshot**
1. **Click "Share" → "Snapshot"**
2. **Set expiration time**
3. **Click "Publish to snapshot.raintank.io"**
4. **Share snapshot URL**

**Option C: Export as PDF** (requires Grafana Enterprise or plugin)

### **8.4: Set as Home Dashboard**

1. **Click "Dashboard settings"**
2. **Click "Make home dashboard"**
3. This dashboard will show when you login

### **8.5: Star Dashboard**

1. **Click star icon** (top right)
2. Dashboard appears in "Starred" section

---

## 💡 Step 9: Tips and Best Practices

### **9.1: Query Optimization**

**Use Appropriate Time Ranges:**
```
[5m]  - Standard for most metrics
[15m] - Smoother graphs, less noise
[1h]  - Long-term trends
[1d]  - Daily patterns
```

**Use Aggregations:**
```
sum by (pod)     - Show per pod
sum              - Total across all pods
avg by (node)    - Average per node
max              - Maximum value
```

**Use Recording Rules for Complex Queries:**
- Pre-calculate expensive queries
- Store results for faster dashboard loading

### **9.2: Dashboard Organization**

**Use Rows to Group Related Panels:**
```
Row 1: Overview (high-level stats)
Row 2: Resources (CPU, memory)
Row 3: Network (traffic, errors)
Row 4: Storage (PVC usage)
Row 5: Application (custom metrics)
```

**Use Variables for Flexibility:**
1. **Dashboard settings → Variables**
2. **Add variable:**
   - Name: `namespace`
   - Type: Query
   - Query: `label_values(kube_pod_info, namespace)`
3. **Use in queries:** `namespace="$namespace"`

**Use Consistent Colors:**
- Green: Normal/healthy
- Yellow: Warning
- Red: Critical
- Blue: Informational

### **9.3: Performance Tips**

**Limit Time Range:**
- Default: Last 6 hours
- Avoid: Last 30 days (slow queries)

**Use Instant Queries for Stats:**
```
# Instead of:
rate(metric[5m])

# Use for stat panels:
metric
```

**Reduce Query Frequency:**
- Dashboard settings → Time options
- Set refresh interval: 1m (instead of 5s)

**Use Query Caching:**
- Prometheus caches recent queries
- Reuse same queries across panels

### **9.4: Alerting from Dashboards**

1. **Click panel title → Edit**
2. **Click "Alert" tab**
3. **Click "Create alert rule from this panel"**
4. **Configure:**
   - Condition: `WHEN last() OF query(A) IS ABOVE 80`
   - Evaluate every: 1m
   - For: 5m
5. **Add notification channel**
6. **Save alert**

### **9.5: Templating**

**Create Dashboard Templates:**
```
Variables:
- $namespace (namespace selector)
- $pod (pod selector)
- $interval (time range selector)

Use in queries:
namespace="$namespace",pod=~"$pod.*"
```

### **9.6: Annotations**

**Add Event Markers:**
1. **Dashboard settings → Annotations**
2. **Add annotation query**
3. **Example:** Show deployment events
   ```
   kube_pod_start_time{namespace="default",pod=~"flask-app.*"}
   ```

---

## 🎯 Quick Reference Commands

### **Common PromQL Patterns**

**Rate (per second):**
```promql
rate(metric[5m])
```

**Sum by label:**
```promql
sum by (pod) (metric)
```

**Percentage:**
```promql
(metric_used / metric_total) * 100
```

**Difference:**
```promql
metric_limit - metric_used
```

**Multiple queries in one panel:**
```
Query A: metric1
Query B: metric2
Both will show on same graph
```

---

## 📚 Additional Resources

### **Grafana Documentation:**
- [Dashboard Guide](https://grafana.com/docs/grafana/latest/dashboards/)
- [Panel Types](https://grafana.com/docs/grafana/latest/panels/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)

### **Practice Queries:**
- Start with simple queries
- Add complexity gradually
- Test in Prometheus UI first (port 9090)

---

## ✅ Checklist

**Before Creating Dashboard:**
- [ ] Grafana is accessible
- [ ] Prometheus data source is configured
- [ ] You know what metrics to monitor

**While Creating Dashboard:**
- [ ] Use descriptive panel titles
- [ ] Add units to all panels
- [ ] Set appropriate thresholds
- [ ] Test queries before saving
- [ ] Arrange panels logically

**After Creating Dashboard:**
- [ ] Save dashboard with description
- [ ] Export JSON backup
- [ ] Share with team
- [ ] Set up alerts if needed
- [ ] Star important dashboards

---

## 🚀 Next Steps

1. **Login to Grafana** using the URL above
2. **Import recommended dashboards** (IDs: 7249, 1860, 6417)
3. **Create Flask App dashboard** following Step 7
4. **Customize** based on your needs
5. **Set up alerts** for critical metrics

---

**Created:** October 9, 2025  
**For:** Flask Photo Gallery Monitoring  
**Grafana Version:** 10.2.2
