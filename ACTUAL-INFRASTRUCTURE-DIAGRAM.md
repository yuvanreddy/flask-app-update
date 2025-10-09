# MyApp - Actual Infrastructure Diagram
**Based on Current Deployment**  
**Generated:** October 9, 2025  
**Cluster:** flask-eks (us-east-1)

---

## 🌐 Complete Infrastructure Architecture (Actual Deployment)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET / END USERS                                      │
│                          http://k8s-flaskdemo-b1a051e724-1178376691                          │
│                                .us-east-1.elb.amazonaws.com                                  │
└──────────────────────────────────────────┬──────────────────────────────────────────────────┘
                                           │
                                           │ HTTP Port 80
                                           ↓
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              AWS APPLICATION LOAD BALANCER (ALB)                             │
│                                                                                              │
│  DNS: k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com                       │
│  Scheme: internet-facing                                                                     │
│  Type: application                                                                           │
│  Managed by: AWS Load Balancer Controller                                                    │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  LISTENER                                                                           │     │
│  │  ├─ Protocol: HTTP                                                                  │     │
│  │  ├─ Port: 80                                                                        │     │
│  │  └─ Default Action: Forward to Target Group                                        │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  TARGET GROUP                                                                       │     │
│  │  ├─ Target Type: IP (Pod IPs directly)                                             │     │
│  │  ├─ Protocol: HTTP                                                                  │     │
│  │  ├─ Port: 5000                                                                      │     │
│  │  ├─ Health Check:                                                                   │     │
│  │  │  ├─ Path: /health                                                                │     │
│  │  │  ├─ Interval: 30 seconds                                                         │     │
│  │  │  ├─ Timeout: 5 seconds                                                           │     │
│  │  │  ├─ Healthy Threshold: 2                                                         │     │
│  │  │  └─ Unhealthy Threshold: 3                                                       │     │
│  │  └─ Registered Targets:                                                             │     │
│  │     └─ 10.0.3.100:5000 (healthy) ✓                                                  │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────┬──────────────────────────────────────────────────┘
                                           │
                                           │ Routes to Pod IP
                                           ↓
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                  AWS VPC (10.0.0.0/16)                                       │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  PUBLIC SUBNETS (Internet Gateway)                                                  │     │
│  │  ├─ 10.0.101.0/24 (us-east-1a) - NAT Gateway                                        │     │
│  │  ├─ 10.0.102.0/24 (us-east-1b) - NAT Gateway                                        │     │
│  │  └─ 10.0.103.0/24 (us-east-1c) - NAT Gateway                                        │     │
│  │                                                                                      │     │
│  │  Purpose: ALB, NAT Gateways, Internet Gateway                                       │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
│                                           │                                                  │
│                                           │ NAT Gateway                                      │
│                                           ↓                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  PRIVATE SUBNETS (EKS Worker Nodes)                                                 │     │
│  │  ├─ 10.0.1.0/24 (us-east-1a)                                                        │     │
│  │  ├─ 10.0.2.0/24 (us-east-1b)                                                        │     │
│  │  └─ 10.0.3.0/24 (us-east-1c)                                                        │     │
│  │                                                                                      │     │
│  │  Purpose: EKS worker nodes, pods (no direct internet access)                        │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                         EKS CLUSTER: flask-eks                                       │    │
│  │                         Version: 1.28.15-eks-113cf36                                 │    │
│  │                         Endpoint: 1E25F8C93ACAA2E6DE45E360E8888F47.gr7.us-east-1... │    │
│  ├─────────────────────────────────────────────────────────────────────────────────────┤    │
│  │                                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐   │    │
│  │  │  WORKER NODE 1                                                                │   │    │
│  │  │  ├─ Name: ip-10-0-1-237.ec2.internal                                          │   │    │
│  │  │  ├─ Instance Type: t3.medium                                                  │   │    │
│  │  │  ├─ Private IP: 10.0.1.237                                                    │   │    │
│  │  │  ├─ Subnet: 10.0.1.0/24 (us-east-1a)                                          │   │    │
│  │  │  ├─ OS: Amazon Linux 2                                                        │   │    │
│  │  │  ├─ Kernel: 5.10.244-240.965.amzn2.x86_64                                     │   │    │
│  │  │  ├─ Container Runtime: containerd 1.7.27                                      │   │    │
│  │  │  ├─ Status: Ready ✓                                                           │   │    │
│  │  │  └─ Running Pods: (System pods)                                               │   │    │
│  │  └──────────────────────────────────────────────────────────────────────────────┘   │    │
│  │                                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐   │    │
│  │  │  WORKER NODE 2                                                                │   │    │
│  │  │  ├─ Name: ip-10-0-3-134.ec2.internal                                          │   │    │
│  │  │  ├─ Instance Type: t3.medium                                                  │   │    │
│  │  │  ├─ Private IP: 10.0.3.134                                                    │   │    │
│  │  │  ├─ Subnet: 10.0.3.0/24 (us-east-1c)                                          │   │    │
│  │  │  ├─ OS: Amazon Linux 2                                                        │   │    │
│  │  │  ├─ Kernel: 5.10.244-240.965.amzn2.x86_64                                     │   │    │
│  │  │  ├─ Container Runtime: containerd 1.7.27                                      │   │    │
│  │  │  ├─ Status: Ready ✓                                                           │   │    │
│  │  │  └─ Running Pods: flask-app-65fbfd86bb-94pln                                  │   │    │
│  │  │                                                                                │   │    │
│  │  │  ┌────────────────────────────────────────────────────────────────────────┐   │   │    │
│  │  │  │  POD: flask-app-65fbfd86bb-94pln                                        │   │   │    │
│  │  │  │  ├─ Pod IP: 10.0.3.100                                                  │   │   │    │
│  │  │  │  ├─ Namespace: default                                                  │   │   │    │
│  │  │  │  ├─ Status: Running ✓                                                   │   │   │    │
│  │  │  │  ├─ Restarts: 0                                                         │   │   │    │
│  │  │  │  ├─ Age: 60 minutes                                                     │   │   │    │
│  │  │  │  │                                                                       │   │   │    │
│  │  │  │  ├─ CONTAINER: flask                                                    │   │   │    │
│  │  │  │  │  ├─ Image: docker.cloudsmith.io/flask-sample-app/                   │   │   │    │
│  │  │  │  │  │         photouploadd-app/flask-devops-demo:latest-xxxxxxx        │   │   │    │
│  │  │  │  │  ├─ Port: 5000                                                       │   │   │    │
│  │  │  │  │  ├─ State: Running                                                   │   │   │    │
│  │  │  │  │  ├─ Ready: True ✓                                                    │   │   │    │
│  │  │  │  │  │                                                                    │   │   │    │
│  │  │  │  │  ├─ Health Checks:                                                   │   │   │    │
│  │  │  │  │  │  ├─ Liveness: GET /health (every 30s)                            │   │   │    │
│  │  │  │  │  │  └─ Readiness: GET /health (every 10s)                           │   │   │    │
│  │  │  │  │  │                                                                    │   │   │    │
│  │  │  │  │  ├─ Resource Limits:                                                 │   │   │    │
│  │  │  │  │  │  ├─ CPU: 500m                                                     │   │   │    │
│  │  │  │  │  │  └─ Memory: 512Mi                                                 │   │   │    │
│  │  │  │  │  │                                                                    │   │   │    │
│  │  │  │  │  └─ Volume Mounts:                                                   │   │   │    │
│  │  │  │  │     ├─ /app/static/uploads/photos → flask-app-uploads-pvc           │   │   │    │
│  │  │  │  │     ├─ /app/static/thumbnails → flask-app-thumbnails-pvc            │   │   │    │
│  │  │  │  │     └─ /app/instance → flask-app-db-pvc                             │   │   │    │
│  │  │  │  │                                                                       │   │   │    │
│  │  │  │  └─ APPLICATION PROCESS:                                                │   │   │    │
│  │  │  │     ├─ Flask Web Server (Python 3.11)                                   │   │   │    │
│  │  │  │     ├─ Listening on: 0.0.0.0:5000                                       │   │   │    │
│  │  │  │     ├─ Process: python app.py                                           │   │   │    │
│  │  │  │     ├─ User: appuser (non-root)                                         │   │   │    │
│  │  │  │     └─ Working Directory: /app                                          │   │   │    │
│  │  │  └────────────────────────────────────────────────────────────────────────┘   │   │    │
│  │  └──────────────────────────────────────────────────────────────────────────────┘   │    │
│  │                                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐   │    │
│  │  │  KUBERNETES SERVICE: flask-svc                                                │   │    │
│  │  │  ├─ Type: ClusterIP                                                          │   │    │
│  │  │  ├─ Cluster IP: 172.20.153.248 (internal only)                              │   │    │
│  │  │  ├─ Port: 80 → Target Port: 5000                                            │   │    │
│  │  │  ├─ Selector: app=flask-app                                                 │   │    │
│  │  │  └─ Endpoints:                                                               │   │    │
│  │  │     └─ 10.0.3.100:5000 (Pod IP)                                             │   │    │
│  │  └──────────────────────────────────────────────────────────────────────────────┘   │    │
│  │                                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐   │    │
│  │  │  KUBERNETES INGRESS: flask-alb                                                │   │    │
│  │  │  ├─ IngressClass: alb                                                         │   │    │
│  │  │  ├─ Address: k8s-flaskdemo-b1a051e724-1178376691.us-east-1...                │   │    │
│  │  │  ├─ Rules:                                                                    │   │    │
│  │  │  │  └─ Path: / → Backend: flask-svc:80                                       │   │    │
│  │  │  └─ Annotations:                                                              │   │    │
│  │  │     ├─ scheme: internet-facing                                               │   │    │
│  │  │     ├─ target-type: ip                                                       │   │    │
│  │  │     ├─ healthcheck-path: /health                                             │   │    │
│  │  │     └─ group.name: flask-demo                                                │   │    │
│  │  └──────────────────────────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              AWS EBS VOLUMES (Persistent Storage)                            │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  VOLUME 1: flask-app-uploads-pvc                                                    │     │
│  │  ├─ Volume ID: pvc-6c192853-9252-4cd3-bce1-005d9911a495                            │     │
│  │  ├─ Type: gp2 (General Purpose SSD)                                                │     │
│  │  ├─ Size: 10 GiB                                                                   │     │
│  │  ├─ Status: Bound ✓                                                                │     │
│  │  ├─ Access Mode: ReadWriteOnce (RWO)                                               │     │
│  │  ├─ Mounted To: Pod flask-app-65fbfd86bb-94pln                                     │     │
│  │  ├─ Mount Path: /app/static/uploads/photos                                         │     │
│  │  └─ Purpose: Store uploaded photo files                                            │     │
│  │     └─ Files: {uuid}_{filename}.jpg, .png, .gif                                    │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  VOLUME 2: flask-app-thumbnails-pvc                                                 │     │
│  │  ├─ Volume ID: pvc-34fd1091-904c-4ad4-b9bb-86abc7064f31                            │     │
│  │  ├─ Type: gp2 (General Purpose SSD)                                                │     │
│  │  ├─ Size: 5 GiB                                                                    │     │
│  │  ├─ Status: Bound ✓                                                                │     │
│  │  ├─ Access Mode: ReadWriteOnce (RWO)                                               │     │
│  │  ├─ Mounted To: Pod flask-app-65fbfd86bb-94pln                                     │     │
│  │  ├─ Mount Path: /app/static/thumbnails                                             │     │
│  │  └─ Purpose: Store thumbnail images (300x300)                                      │     │
│  │     └─ Files: {photo_id}_thumb.jpg                                                 │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐     │
│  │  VOLUME 3: flask-app-db-pvc                                                         │     │
│  │  ├─ Volume ID: pvc-a45a9cd8-1b6f-467b-81c8-a58a2e098fb4                            │     │
│  │  ├─ Type: gp2 (General Purpose SSD)                                                │     │
│  │  ├─ Size: 5 GiB                                                                    │     │
│  │  ├─ Status: Bound ✓                                                                │     │
│  │  ├─ Access Mode: ReadWriteOnce (RWO)                                               │     │
│  │  ├─ Mounted To: Pod flask-app-65fbfd86bb-94pln                                     │     │
│  │  ├─ Mount Path: /app/instance                                                      │     │
│  │  └─ Purpose: Store SQLite database                                                 │     │
│  │     └─ File: /app/instance/photos.db                                               │     │
│  │                                                                                     │     │
│  │     DATABASE SCHEMA:                                                               │     │
│  │     ┌─────────────────────────────────────────────────────────────┐                │     │
│  │     │  Table: photo                                                │                │     │
│  │     │  ├─ id (VARCHAR(36), PRIMARY KEY) - UUID                    │                │     │
│  │     │  ├─ filename (VARCHAR(255)) - Unique filename               │                │     │
│  │     │  ├─ original_filename (VARCHAR(255)) - Original name        │                │     │
│  │     │  ├─ file_size (INTEGER) - Size in bytes                     │                │     │
│  │     │  ├─ mime_type (VARCHAR(100)) - image/jpeg, etc.             │                │     │
│  │     │  ├─ upload_date (DATETIME) - Timestamp                      │                │     │
│  │     │  └─ description (TEXT) - Optional description               │                │     │
│  │     └─────────────────────────────────────────────────────────────┘                │     │
│  └────────────────────────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Traffic Flow (Request Journey)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 1: User Request                                                                │
│  User Browser → http://k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com│
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 2: DNS Resolution                                                              │
│  DNS Query → AWS Route 53                                                            │
│  Response → ALB IP Addresses (multiple IPs across AZs)                               │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 3: ALB Receives Request                                                        │
│  ├─ ALB: k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com            │
│  ├─ Listener: HTTP:80                                                                │
│  ├─ Check: Health of target 10.0.3.100:5000                                          │
│  └─ Status: Healthy ✓                                                                │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 4: Forward to Pod IP                                                           │
│  ALB → 10.0.3.100:5000 (Pod IP directly, no intermediate hops)                       │
│  Protocol: HTTP                                                                      │
│  Path: / (or /upload, /health, etc.)                                                 │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 5: Pod Receives Request                                                        │
│  ├─ Pod: flask-app-65fbfd86bb-94pln                                                  │
│  ├─ Container: flask                                                                 │
│  ├─ Process: Python Flask app.py                                                     │
│  └─ Listening: 0.0.0.0:5000                                                          │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 6: Flask Application Processing                                                │
│  ├─ Route Matching: @app.route('/') or @app.route('/upload')                        │
│  ├─ Database Query: SQLite at /app/instance/photos.db                               │
│  │  └─ SELECT * FROM photo ORDER BY upload_date DESC                                │
│  ├─ File Access: /app/static/uploads/photos/{filename}                              │
│  │  └─ Read from EBS volume: flask-app-uploads-pvc                                  │
│  ├─ Thumbnail Access: /app/static/thumbnails/{photo_id}_thumb.jpg                   │
│  │  └─ Read from EBS volume: flask-app-thumbnails-pvc                               │
│  └─ Render Template: templates/index.html or upload.html                            │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  STEP 7: Response Back to User                                                       │
│  Flask → Pod (10.0.3.100:5000) → ALB → Internet → User Browser                      │
│  ├─ Status: 200 OK                                                                   │
│  ├─ Content-Type: text/html or image/jpeg                                            │
│  └─ Body: HTML page or image binary                                                  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Photo Upload Flow (Data Persistence)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  1. User Uploads Photo via Web Form                                                  │
│     POST /upload                                                                     │
│     Content-Type: multipart/form-data                                                │
│     Body: photo file + description                                                   │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  2. ALB Routes to Pod                                                                │
│     ALB → 10.0.3.100:5000                                                            │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  3. Flask Processes Upload                                                           │
│     ├─ Validate file type (jpg, png, gif)                                           │
│     ├─ Generate UUID: a1b2c3d4-e5f6-7890-abcd-ef1234567890                          │
│     └─ Create unique filename: {uuid}_{original_filename}                           │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  4. Save Photo to EBS Volume                                                         │
│     ├─ Write to: /app/static/uploads/photos/{uuid}_{filename}.jpg                   │
│     ├─ EBS Volume: flask-app-uploads-pvc (10 GiB)                                   │
│     ├─ Volume ID: pvc-6c192853-9252-4cd3-bce1-005d9911a495                          │
│     └─ File persists even if pod restarts                                           │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  5. Create Thumbnail                                                                 │
│     ├─ Open image with PIL (Python Imaging Library)                                 │
│     ├─ Resize to 300x300 (maintain aspect ratio)                                    │
│     ├─ Convert to JPEG                                                               │
│     ├─ Save to: /app/static/thumbnails/{photo_id}_thumb.jpg                         │
│     ├─ EBS Volume: flask-app-thumbnails-pvc (5 GiB)                                 │
│     └─ Volume ID: pvc-34fd1091-904c-4ad4-b9bb-86abc7064f31                          │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  6. Save Metadata to Database                                                        │
│     ├─ Database: SQLite at /app/instance/photos.db                                  │
│     ├─ EBS Volume: flask-app-db-pvc (5 GiB)                                         │
│     ├─ Volume ID: pvc-a45a9cd8-1b6f-467b-81c8-a58a2e098fb4                          │
│     │                                                                                │
│     └─ INSERT INTO photo VALUES:                                                    │
│        ├─ id: a1b2c3d4-e5f6-7890-abcd-ef1234567890                                  │
│        ├─ filename: a1b2c3d4-e5f6-7890-abcd-ef1234567890_vacation.jpg               │
│        ├─ original_filename: vacation.jpg                                           │
│        ├─ file_size: 2457600 (bytes)                                                │
│        ├─ mime_type: image/jpeg                                                     │
│        ├─ upload_date: 2025-10-09 09:00:00                                          │
│        └─ description: "My vacation photo"                                          │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  7. Response to User                                                                 │
│     ├─ Status: 302 Redirect                                                         │
│     ├─ Location: /photo/{photo_id}                                                  │
│     └─ User sees uploaded photo with metadata                                       │
└──────────────────────────────────────────────────────────────────────────────────────┘

DATA PERSISTENCE:
✓ Photo File → EBS Volume (survives pod restarts)
✓ Thumbnail → EBS Volume (survives pod restarts)
✓ Metadata → SQLite on EBS Volume (survives pod restarts)
```

---

## 🔍 Component Details

### **ALB (Application Load Balancer)**
```
Name: k8s-flaskdemo-b1a051e724
DNS: k8s-flaskdemo-b1a051e724-1178376691.us-east-1.elb.amazonaws.com
Type: application
Scheme: internet-facing
IP Address Type: ipv4
Availability Zones: us-east-1a, us-east-1b, us-east-1c

Listener:
├─ Protocol: HTTP
├─ Port: 80
└─ Default Action: Forward to Target Group

Target Group:
├─ Name: k8s-default-flasksvc-xxxxxxxxxx
├─ Target Type: IP
├─ Protocol: HTTP
├─ Port: 5000
├─ Health Check:
│  ├─ Protocol: HTTP
│  ├─ Path: /health
│  ├─ Interval: 30s
│  ├─ Timeout: 5s
│  ├─ Healthy Threshold: 2
│  └─ Unhealthy Threshold: 3
└─ Targets:
   └─ 10.0.3.100:5000 (healthy)

Tags:
├─ Environment: production
├─ Application: flask-photo-gallery
├─ elbv2.k8s.aws/cluster: flask-eks
└─ ingress.k8s.aws/stack: flask-demo
```

### **EKS Worker Nodes**
```
Node 1:
├─ Name: ip-10-0-1-237.ec2.internal
├─ Instance ID: i-xxxxxxxxxxxxxxxxx
├─ Instance Type: t3.medium (2 vCPU, 4 GiB RAM)
├─ AMI: Amazon EKS Optimized Amazon Linux 2
├─ Private IP: 10.0.1.237
├─ Subnet: 10.0.1.0/24 (us-east-1a)
├─ Security Group: eks-cluster-sg-flask-eks-xxxxxxxxxx
├─ IAM Role: flask-eks-node-group-role
├─ Status: Ready
├─ Kubelet Version: v1.28.15-eks-113cf36
├─ Container Runtime: containerd://1.7.27
└─ Capacity:
   ├─ CPU: 2
   ├─ Memory: 3.77 GiB
   └─ Pods: 17

Node 2:
├─ Name: ip-10-0-3-134.ec2.internal
├─ Instance ID: i-xxxxxxxxxxxxxxxxx
├─ Instance Type: t3.medium (2 vCPU, 4 GiB RAM)
├─ AMI: Amazon EKS Optimized Amazon Linux 2
├─ Private IP: 10.0.3.134
├─ Subnet: 10.0.3.0/24 (us-east-1c)
├─ Security Group: eks-cluster-sg-flask-eks-xxxxxxxxxx
├─ IAM Role: flask-eks-node-group-role
├─ Status: Ready
├─ Kubelet Version: v1.28.15-eks-113cf36
├─ Container Runtime: containerd://1.7.27
├─ Running Pods:
│  └─ flask-app-65fbfd86bb-94pln
└─ Capacity:
   ├─ CPU: 2
   ├─ Memory: 3.77 GiB
   └─ Pods: 17
```

### **Application Pod**
```
Pod: flask-app-65fbfd86bb-94pln
├─ Namespace: default
├─ Node: ip-10-0-3-134.ec2.internal (10.0.3.134)
├─ Pod IP: 10.0.3.100
├─ Status: Running
├─ QoS Class: Burstable
├─ Controlled By: ReplicaSet/flask-app-65fbfd86bb
├─ Age: 60 minutes
├─ Restarts: 0

Container: flask
├─ Image: docker.cloudsmith.io/flask-sample-app/photouploadd-app/flask-devops-demo:latest-xxxxxxx
├─ Image Pull Policy: Always
├─ Port: 5000/TCP
├─ State: Running
├─ Ready: True
├─ Restart Count: 0

Resources:
├─ Limits:
│  ├─ CPU: 500m
│  └─ Memory: 512Mi
└─ Requests:
   ├─ CPU: 250m
   └─ Memory: 256Mi

Liveness Probe:
├─ Type: HTTP GET
├─ Path: /health
├─ Port: 5000
├─ Initial Delay: 30s
├─ Period: 30s
├─ Timeout: 3s
└─ Failure Threshold: 3

Readiness Probe:
├─ Type: HTTP GET
├─ Path: /health
├─ Port: 5000
├─ Initial Delay: 10s
├─ Period: 10s
├─ Timeout: 3s
└─ Failure Threshold: 3

Volume Mounts:
├─ /app/static/uploads/photos
│  └─ PVC: flask-app-uploads-pvc (10Gi)
├─ /app/static/thumbnails
│  └─ PVC: flask-app-thumbnails-pvc (5Gi)
└─ /app/instance
   └─ PVC: flask-app-db-pvc (5Gi)

Environment Variables:
├─ PORT: 5000
├─ FLASK_ENV: production
└─ DATABASE_URL: sqlite:////app/instance/photos.db
```

### **Persistent Volumes (EBS)**
```
Volume 1: flask-app-uploads-pvc
├─ PVC Name: flask-app-uploads-pvc
├─ PV Name: pvc-6c192853-9252-4cd3-bce1-005d9911a495
├─ Storage Class: gp2
├─ Capacity: 10 GiB
├─ Access Mode: ReadWriteOnce
├─ Status: Bound
├─ Reclaim Policy: Delete
├─ Volume Mode: Filesystem
├─ Mounted To: flask-app-65fbfd86bb-94pln
├─ Mount Path: /app/static/uploads/photos
├─ AWS EBS Volume ID: vol-xxxxxxxxxxxxxxxxx
├─ Volume Type: gp2 (General Purpose SSD)
├─ IOPS: 100 (baseline)
└─ Throughput: 128 MiB/s

Volume 2: flask-app-thumbnails-pvc
├─ PVC Name: flask-app-thumbnails-pvc
├─ PV Name: pvc-34fd1091-904c-4ad4-b9bb-86abc7064f31
├─ Storage Class: gp2
├─ Capacity: 5 GiB
├─ Access Mode: ReadWriteOnce
├─ Status: Bound
├─ Reclaim Policy: Delete
├─ Volume Mode: Filesystem
├─ Mounted To: flask-app-65fbfd86bb-94pln
├─ Mount Path: /app/static/thumbnails
├─ AWS EBS Volume ID: vol-xxxxxxxxxxxxxxxxx
├─ Volume Type: gp2 (General Purpose SSD)
├─ IOPS: 100 (baseline)
└─ Throughput: 128 MiB/s

Volume 3: flask-app-db-pvc
├─ PVC Name: flask-app-db-pvc
├─ PV Name: pvc-a45a9cd8-1b6f-467b-81c8-a58a2e098fb4
├─ Storage Class: gp2
├─ Capacity: 5 GiB
├─ Access Mode: ReadWriteOnce
├─ Status: Bound
├─ Reclaim Policy: Delete
├─ Volume Mode: Filesystem
├─ Mounted To: flask-app-65fbfd86bb-94pln
├─ Mount Path: /app/instance
├─ AWS EBS Volume ID: vol-xxxxxxxxxxxxxxxxx
├─ Volume Type: gp2 (General Purpose SSD)
├─ IOPS: 100 (baseline)
├─ Throughput: 128 MiB/s
└─ Contains: SQLite database (photos.db)
```

---

## 🎯 Key Takeaways

### **Current Deployment Status**
✅ **Cluster**: flask-eks (ACTIVE)  
✅ **Nodes**: 2 worker nodes (t3.medium) across 2 AZs  
✅ **Pods**: 1 pod running (flask-app-65fbfd86bb-94pln)  
✅ **Service**: flask-svc (ClusterIP: 172.20.153.248)  
✅ **Ingress**: flask-alb with ALB provisioned  
✅ **Storage**: 3 EBS volumes (10Gi + 5Gi + 5Gi) all bound  
✅ **ALB**: Public endpoint accessible  

### **Network Architecture**
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 3 subnets across 3 AZs (for ALB)
- **Private Subnets**: 3 subnets across 3 AZs (for worker nodes)
- **Pod Network**: 10.0.x.x (VPC-CNI)
- **Service Network**: 172.20.x.x (ClusterIP range)

### **Data Persistence**
- **Photos**: Stored on 10 GiB EBS volume
- **Thumbnails**: Stored on 5 GiB EBS volume
- **Database**: SQLite on 5 GiB EBS volume
- **Persistence**: All data survives pod restarts/recreations

### **High Availability**
- **Multi-AZ**: Nodes in us-east-1a and us-east-1c
- **ALB**: Distributes traffic across all healthy pods
- **Health Checks**: 4 layers (App, Liveness, Readiness, ALB)
- **Auto-scaling**: Node group can scale from 2 to 4 nodes

---

**Diagram Generated:** October 9, 2025  
**Based on Live Deployment:** flask-eks cluster  
**Region:** us-east-1
