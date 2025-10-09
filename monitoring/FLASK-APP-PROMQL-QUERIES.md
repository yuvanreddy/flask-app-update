# Flask Photo Gallery - PromQL Queries Guide

**Application:** Flask Photo Gallery  
**Namespace:** default  
**Deployment:** flask-app  
**Date:** October 9, 2025

---

## 📋 Table of Contents

1. [Pod & Container Metrics](#pod--container-metrics)
2. [CPU Metrics](#cpu-metrics)
3. [Memory Metrics](#memory-metrics)
4. [Network Metrics](#network-metrics)
5. [Storage Metrics](#storage-metrics)
6. [Health & Availability](#health--availability)
7. [Resource Limits & Requests](#resource-limits--requests)
8. [Performance Metrics](#performance-metrics)
9. [Alert Queries](#alert-queries)
10. [Dashboard Queries](#dashboard-queries)

---

## 🎯 Pod & Container Metrics

### **1. Number of Running Pods**
```promql
# Count running Flask app pods
count(kube_pod_status_phase{namespace="default",pod=~"flask-app.*",phase="Running"})
```
**Use:** Single stat panel showing "1/1" or "2/2"  
**Expected:** Should match desired replica count

### **2. Pod Status by Phase**
```promql
# Show pod count by phase (Running, Pending, Failed, etc.)
count by (phase) (kube_pod_status_phase{namespace="default",pod=~"flask-app.*"})
```
**Use:** Pie chart or stat panel  
**Expected:** All pods should be in "Running" phase

### **3. Pod Uptime**
```promql
# Time since pod started (in seconds)
time() - kube_pod_start_time{namespace="default",pod=~"flask-app.*"}
```
**Use:** Stat panel with unit "seconds" or "duration"  
**Expected:** Increasing value (higher = more stable)

### **4. Container Restart Count**
```promql
# Total restarts per pod
sum by (pod) (kube_pod_container_status_restarts_total{namespace="default",pod=~"flask-app.*"})
```
**Use:** Stat panel or table  
**Expected:** 0 (no restarts)

### **5. Container Restart Rate (Last 15 minutes)**
```promql
# Restarts per second
rate(kube_pod_container_status_restarts_total{namespace="default",pod=~"flask-app.*"}[15m])
```
**Use:** Graph panel  
**Expected:** 0 (no restarts)

### **6. Pod Ready Status**
```promql
# 1 = ready, 0 = not ready
kube_pod_status_ready{namespace="default",pod=~"flask-app.*",condition="true"}
```
**Use:** Stat panel  
**Expected:** 1 (ready)

---

## 💻 CPU Metrics

### **7. Current CPU Usage (Cores)**
```promql
# CPU usage in cores (e.g., 0.05 = 50 millicores)
sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod)
```
**Use:** Graph panel  
**Expected:** 0.01 - 0.1 cores (10-100 millicores) for idle app

### **8. CPU Usage (Millicores)**
```promql
# CPU usage in millicores (easier to read)
sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod) * 1000
```
**Use:** Graph panel with unit "millicores"  
**Expected:** 10-100m for idle, up to 500m under load

### **9. CPU Usage Percentage (vs Limit)**
```promql
# Percentage of CPU limit used
(
  sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod)
  /
  sum(kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"}) by (pod)
) * 100
```
**Use:** Gauge panel (0-100%)  
**Expected:** 10-20% idle, <80% under load

### **10. CPU Usage Percentage (vs Request)**
```promql
# Percentage of CPU request used
(
  sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod)
  /
  sum(kube_pod_container_resource_requests{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"}) by (pod)
) * 100
```
**Use:** Gauge panel  
**Expected:** 20-40% idle

### **11. CPU Throttling**
```promql
# CPU throttling rate (seconds throttled per second)
rate(container_cpu_cfs_throttled_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])
```
**Use:** Graph panel  
**Expected:** 0 (no throttling)  
**Alert if:** > 0.1 (10% of time throttled)

### **12. CPU Throttling Percentage**
```promql
# Percentage of time CPU was throttled
rate(container_cpu_cfs_throttled_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])
/
rate(container_cpu_cfs_periods_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])
* 100
```
**Use:** Graph panel  
**Expected:** 0%

---

## 🧠 Memory Metrics

### **13. Current Memory Usage (Bytes)**
```promql
# Memory usage in bytes
sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod)
```
**Use:** Graph panel with unit "bytes"  
**Expected:** 150-200 MB for Flask app

### **14. Memory Usage (MB)**
```promql
# Memory usage in megabytes
sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod) / 1024 / 1024
```
**Use:** Graph panel with unit "MB"  
**Expected:** 150-200 MB

### **15. Memory Usage Percentage (vs Limit)**
```promql
# Percentage of memory limit used
(
  sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod)
  /
  sum(kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"}) by (pod)
) * 100
```
**Use:** Gauge panel (0-100%)  
**Expected:** 30-40% idle  
**Alert if:** >90%

### **16. Memory Usage Percentage (vs Request)**
```promql
# Percentage of memory request used
(
  sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod)
  /
  sum(kube_pod_container_resource_requests{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"}) by (pod)
) * 100
```
**Use:** Gauge panel  
**Expected:** 60-80%

### **17. Memory RSS (Resident Set Size)**
```promql
# Actual memory used by process
sum(container_memory_rss{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod) / 1024 / 1024
```
**Use:** Graph panel with unit "MB"  
**Expected:** Similar to working set

### **18. Memory Cache**
```promql
# Memory used for cache
sum(container_memory_cache{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod) / 1024 / 1024
```
**Use:** Graph panel  
**Expected:** Low for Flask app

### **19. Memory Swap Usage**
```promql
# Swap usage (should be 0)
sum(container_memory_swap{namespace="default",pod=~"flask-app.*",container="flask"}) by (pod) / 1024 / 1024
```
**Use:** Stat panel  
**Expected:** 0 MB (no swap)

---

## 🌐 Network Metrics

### **20. Network Received Rate (Bytes/sec)**
```promql
# Incoming network traffic
sum(rate(container_network_receive_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod)
```
**Use:** Graph panel with unit "Bps"  
**Expected:** Low when idle, spikes during photo uploads

### **21. Network Transmitted Rate (Bytes/sec)**
```promql
# Outgoing network traffic
sum(rate(container_network_transmit_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod)
```
**Use:** Graph panel with unit "Bps"  
**Expected:** Higher than received (serving photos)

### **22. Network I/O Combined (MB/sec)**
```promql
# Total network I/O
(
  sum(rate(container_network_receive_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod)
  +
  sum(rate(container_network_transmit_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) by (pod)
) / 1024 / 1024
```
**Use:** Graph panel with unit "MBps"  
**Expected:** <1 MBps for typical usage

### **23. Network Receive Errors**
```promql
# Network receive errors per second
rate(container_network_receive_errors_total{namespace="default",pod=~"flask-app.*"}[5m])
```
**Use:** Graph panel  
**Expected:** 0  
**Alert if:** >0

### **24. Network Transmit Errors**
```promql
# Network transmit errors per second
rate(container_network_transmit_errors_total{namespace="default",pod=~"flask-app.*"}[5m])
```
**Use:** Graph panel  
**Expected:** 0  
**Alert if:** >0

### **25. Network Dropped Packets (Receive)**
```promql
# Dropped incoming packets per second
rate(container_network_receive_packets_dropped_total{namespace="default",pod=~"flask-app.*"}[5m])
```
**Use:** Graph panel  
**Expected:** 0

### **26. Network Dropped Packets (Transmit)**
```promql
# Dropped outgoing packets per second
rate(container_network_transmit_packets_dropped_total{namespace="default",pod=~"flask-app.*"}[5m])
```
**Use:** Graph panel  
**Expected:** 0

---

## 💾 Storage Metrics

### **27. Photos PVC Usage (Bytes)**
```promql
# Photos storage used
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"}
```
**Use:** Stat panel with unit "bytes"  
**Expected:** Increases as photos are uploaded

### **28. Photos PVC Usage (GB)**
```promql
# Photos storage in gigabytes
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"} / 1024 / 1024 / 1024
```
**Use:** Gauge panel with unit "GB"  
**Expected:** <1 GB initially

### **29. Photos PVC Usage Percentage**
```promql
# Percentage of photos storage used
(
  kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"}
  /
  kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"}
) * 100
```
**Use:** Gauge panel (0-100%)  
**Expected:** <1%  
**Alert if:** >85%

### **30. Photos PVC Available Space (GB)**
```promql
# Available space for photos
kubelet_volume_stats_available_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"} / 1024 / 1024 / 1024
```
**Use:** Stat panel with unit "GB"  
**Expected:** ~10 GB

### **31. Thumbnails PVC Usage (MB)**
```promql
# Thumbnails storage in megabytes
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-thumbnails-pvc"} / 1024 / 1024
```
**Use:** Stat panel with unit "MB"  
**Expected:** <100 MB

### **32. Thumbnails PVC Usage Percentage**
```promql
# Percentage of thumbnails storage used
(
  kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-thumbnails-pvc"}
  /
  kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim="flask-app-thumbnails-pvc"}
) * 100
```
**Use:** Gauge panel  
**Expected:** <1%

### **33. Database PVC Usage (MB)**
```promql
# Database storage in megabytes
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-db-pvc"} / 1024 / 1024
```
**Use:** Stat panel with unit "MB"  
**Expected:** <50 MB for SQLite

### **34. Database PVC Usage Percentage**
```promql
# Percentage of database storage used
(
  kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-db-pvc"}
  /
  kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim="flask-app-db-pvc"}
) * 100
```
**Use:** Gauge panel  
**Expected:** <1%

### **35. Total Storage Used (All PVCs)**
```promql
# Total storage used by Flask app
sum(kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim=~"flask-app.*"}) / 1024 / 1024 / 1024
```
**Use:** Stat panel with unit "GB"  
**Expected:** <1 GB

### **36. PVC Inode Usage**
```promql
# Percentage of inodes used
(
  kubelet_volume_stats_inodes_used{namespace="default",persistentvolumeclaim=~"flask-app.*"}
  /
  kubelet_volume_stats_inodes{namespace="default",persistentvolumeclaim=~"flask-app.*"}
) * 100
```
**Use:** Gauge panel  
**Expected:** <10%

---

## ✅ Health & Availability

### **37. Pod Availability (Last 24h)**
```promql
# Percentage of time pod was available
avg_over_time(up{job=~".*flask-app.*"}[24h]) * 100
```
**Use:** Stat panel  
**Expected:** 100%

### **38. Deployment Replica Status**
```promql
# Desired vs available replicas
kube_deployment_status_replicas_available{namespace="default",deployment="flask-app"}
/
kube_deployment_spec_replicas{namespace="default",deployment="flask-app"}
* 100
```
**Use:** Gauge panel  
**Expected:** 100%

### **39. Pod Ready Condition**
```promql
# Number of ready pods
sum(kube_pod_status_ready{namespace="default",pod=~"flask-app.*",condition="true"})
```
**Use:** Stat panel  
**Expected:** Equal to replica count

### **40. Container State**
```promql
# Container state (1=running, 0=not running)
kube_pod_container_status_running{namespace="default",pod=~"flask-app.*",container="flask"}
```
**Use:** Stat panel  
**Expected:** 1

### **41. Time Since Last Restart**
```promql
# Seconds since last restart
time() - max(kube_pod_container_status_last_terminated_timestamp{namespace="default",pod=~"flask-app.*"})
```
**Use:** Stat panel with unit "seconds"  
**Expected:** High value (no recent restarts)

---

## 📊 Resource Limits & Requests

### **42. CPU Limit**
```promql
# CPU limit in millicores
kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"} * 1000
```
**Use:** Stat panel  
**Expected:** 500m

### **43. CPU Request**
```promql
# CPU request in millicores
kube_pod_container_resource_requests{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"} * 1000
```
**Use:** Stat panel  
**Expected:** 250m

### **44. Memory Limit (MB)**
```promql
# Memory limit in megabytes
kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"} / 1024 / 1024
```
**Use:** Stat panel  
**Expected:** 512 MB

### **45. Memory Request (MB)**
```promql
# Memory request in megabytes
kube_pod_container_resource_requests{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"} / 1024 / 1024
```
**Use:** Stat panel  
**Expected:** 256 MB

### **46. CPU Headroom (Available)**
```promql
# Available CPU before hitting limit
(
  kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"}
  -
  rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])
) * 1000
```
**Use:** Stat panel with unit "millicores"  
**Expected:** 400-450m

### **47. Memory Headroom (Available)**
```promql
# Available memory before hitting limit
(
  kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"}
  -
  container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}
) / 1024 / 1024
```
**Use:** Stat panel with unit "MB"  
**Expected:** 300-350 MB

---

## ⚡ Performance Metrics

### **48. File System Reads (Bytes/sec)**
```promql
# Disk read rate
sum(rate(container_fs_reads_bytes_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod)
```
**Use:** Graph panel  
**Expected:** Spikes when serving photos

### **49. File System Writes (Bytes/sec)**
```promql
# Disk write rate
sum(rate(container_fs_writes_bytes_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) by (pod)
```
**Use:** Graph panel  
**Expected:** Spikes during photo uploads

### **50. File System I/O Operations (Reads)**
```promql
# Read operations per second
rate(container_fs_reads_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])
```
**Use:** Graph panel  
**Expected:** Low to moderate

### **51. File System I/O Operations (Writes)**
```promql
# Write operations per second
rate(container_fs_writes_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])
```
**Use:** Graph panel  
**Expected:** Low (only during uploads)

---

## 🚨 Alert Queries

### **52. Pod Down Alert**
```promql
# Alert if no pods are running
sum(kube_pod_status_phase{namespace="default",pod=~"flask-app.*",phase="Running"}) == 0
```
**Alert Condition:** Query returns 1  
**Severity:** Critical  
**Duration:** 5 minutes

### **53. High CPU Alert**
```promql
# Alert if CPU usage > 80% of limit
(
  sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m]))
  /
  sum(kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="cpu"})
) > 0.8
```
**Alert Condition:** Query returns 1  
**Severity:** Warning  
**Duration:** 10 minutes

### **54. High Memory Alert**
```promql
# Alert if memory usage > 90% of limit
(
  sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"})
  /
  sum(kube_pod_container_resource_limits{namespace="default",pod=~"flask-app.*",container="flask",resource="memory"})
) > 0.9
```
**Alert Condition:** Query returns 1  
**Severity:** Warning  
**Duration:** 10 minutes

### **55. Frequent Restarts Alert**
```promql
# Alert if pod restarted in last 15 minutes
rate(kube_pod_container_status_restarts_total{namespace="default",pod=~"flask-app.*"}[15m]) > 0
```
**Alert Condition:** Query returns value > 0  
**Severity:** Warning  
**Duration:** 5 minutes

### **56. Storage Almost Full Alert**
```promql
# Alert if any PVC > 85% full
(
  kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim=~"flask-app.*"}
  /
  kubelet_volume_stats_capacity_bytes{namespace="default",persistentvolumeclaim=~"flask-app.*"}
) > 0.85
```
**Alert Condition:** Query returns 1  
**Severity:** Warning  
**Duration:** 15 minutes

---

## 📊 Dashboard Queries (Combined Panels)

### **57. Resource Usage Overview (Single Panel)**
```promql
# CPU Usage
sum(rate(container_cpu_usage_seconds_total{namespace="default",pod=~"flask-app.*",container="flask"}[5m])) * 1000

# Memory Usage
sum(container_memory_working_set_bytes{namespace="default",pod=~"flask-app.*",container="flask"}) / 1024 / 1024

# Network In
sum(rate(container_network_receive_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) / 1024

# Network Out
sum(rate(container_network_transmit_bytes_total{namespace="default",pod=~"flask-app.*"}[5m])) / 1024
```
**Use:** Multi-query graph panel  
**Display:** 4 lines on same graph

### **58. Storage Overview (Single Panel)**
```promql
# Photos
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-uploads-pvc"} / 1024 / 1024

# Thumbnails
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-thumbnails-pvc"} / 1024 / 1024

# Database
kubelet_volume_stats_used_bytes{namespace="default",persistentvolumeclaim="flask-app-db-pvc"} / 1024 / 1024
```
**Use:** Bar gauge panel  
**Display:** 3 bars showing MB used

### **59. Pod Health Status (Single Panel)**
```promql
# Running Pods
count(kube_pod_status_phase{namespace="default",pod=~"flask-app.*",phase="Running"})

# Ready Pods
sum(kube_pod_status_ready{namespace="default",pod=~"flask-app.*",condition="true"})

# Restarts
sum(kube_pod_container_status_restarts_total{namespace="default",pod=~"flask-app.*"})
```
**Use:** Stat panel with multiple queries  
**Display:** 3 stats side by side

---

## 🎯 Quick Reference Table

| Metric | Query Number | Panel Type | Expected Value |
|--------|--------------|------------|----------------|
| Pods Running | #1 | Stat | 1 |
| CPU Usage | #8 | Graph | 10-100m |
| Memory Usage | #14 | Graph | 150-200 MB |
| Network In | #20 | Graph | Variable |
| Network Out | #21 | Graph | Variable |
| Photos Storage | #28 | Gauge | <1 GB |
| Restarts | #4 | Stat | 0 |
| Uptime | #3 | Stat | Increasing |

---

## 💡 Tips for Using These Queries

### **1. Time Ranges:**
- Use `[5m]` for rate calculations (standard)
- Use `[15m]` for smoother graphs
- Use `[1h]` or `[24h]` for long-term trends

### **2. Aggregations:**
- `sum by (pod)` - Show per pod
- `sum` - Show total across all pods
- `avg` - Show average
- `max` - Show maximum

### **3. Units:**
- CPU: Use millicores (multiply by 1000)
- Memory: Use MB (divide by 1024/1024)
- Storage: Use GB (divide by 1024/1024/1024)
- Network: Use KB/s or MB/s

### **4. Panel Types:**
- **Stat:** Single value (current state)
- **Gauge:** Percentage (0-100%)
- **Graph:** Time series (trends)
- **Bar Gauge:** Multiple values comparison
- **Table:** Detailed breakdown

---

## 🚀 Next Steps

1. **Copy these queries** into Grafana dashboard panels
2. **Adjust time ranges** based on your needs
3. **Set up alerts** using alert queries (#52-56)
4. **Create custom dashboard** with most important metrics
5. **Monitor trends** over days/weeks

---

**Created:** October 9, 2025  
**For Application:** Flask Photo Gallery  
**Cluster:** flask-eks (us-east-1)
