# CPU Stress Testing Guide for Flask App Monitoring

**Purpose:** Test Grafana dashboards and alerts by artificially increasing CPU utilization  
**Date:** October 9, 2025

---

## 🎯 Methods to Increase CPU Utilization

### **Method 1: Install and Run `stress` Tool (Easiest)**

#### **Step 1: Access the Pod**
```powershell
kubectl exec -it flask-app-65fbfd86bb-94pln -n default -- /bin/sh
```

#### **Step 2: Install stress tool**
```bash
# Update package manager
apt-get update

# Install stress tool
apt-get install -y stress

# Verify installation
stress --version
```

#### **Step 3: Run CPU stress test**

**Light Load (50% CPU):**
```bash
# Run 1 CPU worker for 60 seconds
stress --cpu 1 --timeout 60s
```

**Medium Load (100% CPU):**
```bash
# Run 2 CPU workers for 120 seconds
stress --cpu 2 --timeout 120s
```

**Heavy Load (200% CPU - will be throttled):**
```bash
# Run 4 CPU workers for 60 seconds
stress --cpu 4 --timeout 60s
```

**Continuous Load (until stopped):**
```bash
# Run 2 CPU workers indefinitely
stress --cpu 2

# Press Ctrl+C to stop
```

#### **Step 4: Monitor in Grafana**
- Open Grafana dashboard
- Watch CPU usage panel increase
- Check if alerts trigger (if CPU > 80%)

---

### **Method 2: Python CPU Stress Script (No Installation Required)**

#### **Step 1: Access the Pod**
```powershell
kubectl exec -it flask-app-65fbfd86bb-94pln -n default -- /bin/sh
```

#### **Step 2: Create CPU stress script**
```bash
cat > /tmp/cpu_stress.py << 'EOF'
#!/usr/bin/env python3
import multiprocessing
import time
import sys

def cpu_intensive_task(duration):
    """CPU-intensive calculation"""
    end_time = time.time() + duration
    while time.time() < end_time:
        # Perform CPU-intensive operation
        _ = sum(i * i for i in range(10000))

if __name__ == "__main__":
    duration = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    workers = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    
    print(f"Starting {workers} CPU workers for {duration} seconds...")
    
    processes = []
    for i in range(workers):
        p = multiprocessing.Process(target=cpu_intensive_task, args=(duration,))
        p.start()
        processes.append(p)
        print(f"Started worker {i+1}")
    
    # Wait for all processes to complete
    for p in processes:
        p.join()
    
    print("CPU stress test completed!")
EOF

chmod +x /tmp/cpu_stress.py
```

#### **Step 3: Run the script**

**Light Load (1 worker, 60 seconds):**
```bash
python /tmp/cpu_stress.py 60 1
```

**Medium Load (2 workers, 120 seconds):**
```bash
python /tmp/cpu_stress.py 120 2
```

**Heavy Load (4 workers, 60 seconds):**
```bash
python /tmp/cpu_stress.py 60 4
```

---

### **Method 3: HTTP Load Testing (Realistic Scenario)**

This simulates actual user traffic to your Flask app.

#### **Option A: Using Apache Bench (ab)**

**From your local machine:**
```powershell
# Install Apache Bench (if not installed)
choco install apache-httpd

# Send 10000 requests with 100 concurrent connections
ab -n 10000 -c 100 http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com/

# Send continuous requests for 60 seconds
ab -t 60 -c 50 http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com/
```

#### **Option B: Using curl in a loop**

**From your local machine:**
```powershell
# PowerShell loop - 1000 requests
1..1000 | ForEach-Object {
    Invoke-WebRequest -Uri "http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com/" -UseBasicParsing
    Write-Host "Request $_"
}
```

**From inside the pod:**
```bash
# Bash loop - continuous requests
while true; do
    curl -s http://localhost:5000/ > /dev/null
    echo "Request sent"
    sleep 0.1
done

# Press Ctrl+C to stop
```

#### **Option C: Using hey (HTTP load generator)**

**From your local machine:**
```powershell
# Install hey
go install github.com/rakyll/hey@latest

# Or download binary from: https://github.com/rakyll/hey/releases

# Send 10000 requests with 50 workers
hey -n 10000 -c 50 http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com/

# Continuous load for 60 seconds
hey -z 60s -c 50 http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com/
```

---

### **Method 4: Memory Stress Test (Bonus)**

To test memory monitoring as well:

#### **Using stress tool:**
```bash
# Allocate 256MB of memory for 60 seconds
stress --vm 1 --vm-bytes 256M --timeout 60s

# Allocate 400MB (close to limit)
stress --vm 1 --vm-bytes 400M --timeout 60s
```

#### **Using Python:**
```bash
cat > /tmp/memory_stress.py << 'EOF'
#!/usr/bin/env python3
import time

# Allocate 256MB
data = []
for i in range(256):
    data.append(' ' * (1024 * 1024))  # 1MB chunks
    print(f"Allocated {i+1} MB")
    time.sleep(0.1)

print("Holding memory for 60 seconds...")
time.sleep(60)
print("Done!")
EOF

python /tmp/memory_stress.py
```

---

### **Method 5: Combined CPU + Memory Stress**

```bash
# CPU + Memory stress for 120 seconds
stress --cpu 2 --vm 1 --vm-bytes 256M --timeout 120s
```

---

## 📊 What to Monitor in Grafana

### **During Stress Test, Watch These Panels:**

1. **CPU Usage (millicores)**
   - Should increase from ~50m to 400-500m
   - May hit the limit (500m) and get throttled

2. **CPU Usage Percentage**
   - Should increase from ~10% to 80-100%
   - Gauge should turn yellow/red

3. **CPU Throttling**
   - Should show throttling if CPU hits limit
   - Graph will show non-zero values

4. **Memory Usage (if doing memory stress)**
   - Should increase from ~150MB to 400-450MB
   - Gauge should change color

5. **Pod Restarts**
   - Should remain at 0 (pod shouldn't crash)

6. **Network I/O (if doing HTTP load test)**
   - Should show increased traffic

---

## 🚨 Expected Alert Behavior

### **Alerts That Should Trigger:**

**1. High CPU Usage Alert**
- Condition: CPU > 80% for 10 minutes
- Expected: Alert fires after 10 minutes of sustained load
- Severity: Warning

**2. CPU Throttling Alert**
- Condition: CPU throttled > 10% of time
- Expected: Alert fires if stress exceeds pod limits
- Severity: Warning

**3. High Memory Usage Alert** (if doing memory stress)
- Condition: Memory > 90% for 10 minutes
- Expected: Alert fires if memory approaches limit
- Severity: Warning

---

## 🎯 Step-by-Step Testing Procedure

### **Test 1: Light CPU Load**

**Goal:** Verify monitoring is working

```bash
# 1. Access pod
kubectl exec -it flask-app-65fbfd86bb-94pln -n default -- /bin/sh

# 2. Run light stress (1 CPU worker for 60 seconds)
stress --cpu 1 --timeout 60s

# 3. Watch Grafana
# - CPU should increase to ~100-200m
# - No alerts should fire
# - CPU percentage: ~20-40%
```

### **Test 2: Medium CPU Load**

**Goal:** Approach warning threshold

```bash
# 1. Run medium stress (2 CPU workers for 300 seconds = 5 minutes)
stress --cpu 2 --timeout 300s

# 2. Watch Grafana
# - CPU should increase to ~400-450m
# - CPU percentage: ~80-90%
# - Gauges should turn yellow
# - No alerts yet (need 10 minutes)
```

### **Test 3: Heavy CPU Load (Trigger Alerts)**

**Goal:** Trigger high CPU alert

```bash
# 1. Run heavy stress (2 CPU workers for 15 minutes)
stress --cpu 2 --timeout 900s

# 2. Watch Grafana
# - CPU should hit limit (500m)
# - CPU percentage: 100%
# - Gauges should turn red
# - After 10 minutes: Alert should fire
# - Check Alertmanager: http://localhost:9093 (port forward)
```

### **Test 4: HTTP Load Test**

**Goal:** Realistic load simulation

```powershell
# From your local machine
# Send continuous requests for 5 minutes
hey -z 300s -c 50 http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com/

# Watch Grafana:
# - CPU increases based on request processing
# - Network I/O increases
# - More realistic than stress test
```

---

## 🔍 Monitoring Commands

### **Check CPU Usage from Command Line:**

```powershell
# Watch CPU usage in real-time
kubectl top pod flask-app-65fbfd86bb-94pln -n default

# Output:
# NAME                         CPU(cores)   MEMORY(bytes)
# flask-app-65fbfd86bb-94pln   450m         180Mi
```

### **Check if Pod is Being Throttled:**

```powershell
# Check pod events
kubectl describe pod flask-app-65fbfd86bb-94pln -n default | Select-String -Pattern "throttl"

# Check container status
kubectl get pod flask-app-65fbfd86bb-94pln -n default -o jsonpath='{.status.containerStatuses[0].state}'
```

### **View Prometheus Metrics Directly:**

```powershell
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# Open browser: http://localhost:9090
# Run query:
rate(container_cpu_usage_seconds_total{pod=~"flask-app.*"}[5m])
```

---

## 🛑 How to Stop Stress Test

### **If Running in Foreground:**
```bash
# Press Ctrl+C
```

### **If Running in Background:**
```bash
# Find process
ps aux | grep stress

# Kill process
kill <PID>

# Or kill all stress processes
pkill stress
```

### **If Pod is Unresponsive:**
```powershell
# Delete pod (will restart automatically)
kubectl delete pod flask-app-65fbfd86bb-94pln -n default

# New pod will be created immediately
```

---

## 📈 Expected Results

### **Normal State (No Stress):**
```
CPU Usage: 10-50m (2-10%)
Memory Usage: 150-180 MB (29-35%)
Network I/O: Low
Restarts: 0
```

### **During Light Stress (1 CPU worker):**
```
CPU Usage: 100-200m (20-40%)
Memory Usage: 150-180 MB (unchanged)
Network I/O: Low
Restarts: 0
Alerts: None
```

### **During Medium Stress (2 CPU workers):**
```
CPU Usage: 400-500m (80-100%)
Memory Usage: 150-180 MB (unchanged)
Network I/O: Low
Restarts: 0
Alerts: Warning after 10 minutes
```

### **During Heavy Stress (4 CPU workers):**
```
CPU Usage: 500m (100% - hitting limit)
CPU Throttling: Yes (visible in metrics)
Memory Usage: 150-180 MB (unchanged)
Restarts: 0
Alerts: Critical after 10 minutes
```

---

## ⚠️ Important Notes

### **1. Resource Limits:**
Your Flask app has:
- CPU Limit: 500m (0.5 cores)
- Memory Limit: 512 MB

**Don't exceed these limits excessively** or pod may be killed.

### **2. Stress Test Duration:**
- Short tests (1-5 min): Good for quick verification
- Medium tests (10-15 min): Good for triggering alerts
- Long tests (30+ min): Good for sustained load testing

### **3. Cleanup:**
Always stop stress tests when done to avoid:
- Wasting resources
- False alerts
- Impacting other pods on the node

### **4. Node Impact:**
Heavy stress tests may impact other pods on the same node (ip-10-0-3-134.ec2.internal).

---

## 🎯 Quick Commands Reference

```bash
# Light CPU stress (60 seconds)
stress --cpu 1 --timeout 60s

# Medium CPU stress (5 minutes)
stress --cpu 2 --timeout 300s

# Heavy CPU stress (15 minutes - trigger alerts)
stress --cpu 2 --timeout 900s

# Memory stress (256MB for 60 seconds)
stress --vm 1 --vm-bytes 256M --timeout 60s

# Combined stress
stress --cpu 2 --vm 1 --vm-bytes 256M --timeout 300s

# Check CPU usage
kubectl top pod flask-app-65fbfd86bb-94pln -n default

# Stop all stress processes
pkill stress
```

---

## 📊 Grafana Dashboard Checklist

**Before Starting Stress Test:**
- [ ] Grafana dashboard is open
- [ ] CPU usage panel is visible
- [ ] Memory usage panel is visible
- [ ] Time range is set to "Last 15 minutes"
- [ ] Auto-refresh is enabled (30s interval)

**During Stress Test:**
- [ ] CPU usage is increasing
- [ ] Gauges are changing color
- [ ] Graphs are updating
- [ ] No pod restarts

**After Stress Test:**
- [ ] CPU returns to normal
- [ ] Alerts clear (if triggered)
- [ ] Pod is still running
- [ ] No errors in logs

---

**Created:** October 9, 2025  
**For:** Flask Photo Gallery Monitoring Testing  
**Pod:** flask-app-65fbfd86bb-94pln
