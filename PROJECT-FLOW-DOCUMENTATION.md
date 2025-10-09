# MyApp - Complete Project Flow Documentation

**Project Name:** Flask Photo Gallery with Enterprise DevOps Pipeline  
**Author:** Yuvan Reddy  
**Last Updated:** October 9, 2025  
**Version:** 1.0

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Technology Stack](#technology-stack)
4. [Complete Flow Explanation](#complete-flow-explanation)
5. [Application Flow](#application-flow)
6. [CI/CD Pipeline Flow](#cicd-pipeline-flow)
7. [Infrastructure Components](#infrastructure-components)
8. [Security & Authentication](#security--authentication)
9. [Deployment Process](#deployment-process)
10. [Monitoring & Health Checks](#monitoring--health-checks)
11. [Troubleshooting Guide](#troubleshooting-guide)
12. [Best Practices](#best-practices)

---

## 🎯 Project Overview

MyApp is a **production-ready Flask photo gallery application** deployed on AWS EKS (Elastic Kubernetes Service) with a complete enterprise-grade DevOps pipeline.

### **What Does This Project Do?**

- **For End Users:** Upload, view, and manage photos through a web interface
- **For DevOps:** Demonstrates complete CI/CD pipeline with security scanning, containerization, and automated deployment
- **For Infrastructure:** Showcases Infrastructure as Code (Terraform) for AWS EKS cluster provisioning

### **Key Features**

✅ **Application Features:**
- Photo upload with thumbnail generation
- Photo gallery with metadata display
- SQLite database for photo information
- Persistent storage using EBS volumes
- Health check endpoints for monitoring

✅ **DevOps Features:**
- Automated CI/CD with GitHub Actions
- Multi-stage security scanning (SAST, dependency, container)
- Docker containerization with multi-stage builds
- Zero-downtime rolling deployments
- Infrastructure as Code with Terraform

✅ **Security Features:**
- OIDC authentication (no long-lived credentials)
- Bandit (Python SAST scanning)
- Safety (dependency vulnerability scanning)
- Trivy (container image scanning)
- Non-root container execution

---

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          DEVELOPER WORKFLOW                              │
│  Developer writes code → Commits to Git → Pushes to GitHub              │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                     GITHUB ACTIONS CI/CD PIPELINE                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 1: SECURITY SCANNING (2 min)                            │    │
│  │  ├─ Checkout code from repository                              │    │
│  │  ├─ Setup Python 3.11 environment                              │    │
│  │  ├─ Install dependencies (pip install -r requirements.txt)     │    │
│  │  ├─ Run Bandit (Python SAST)                                   │    │
│  │  │  └─ Detects: SQL injection, hardcoded secrets, etc.         │    │
│  │  ├─ Run Safety (Dependency vulnerabilities)                    │    │
│  │  │  └─ Checks: Known CVEs in Python packages                   │    │
│  │  └─ Upload security reports as artifacts                       │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                 ↓                                        │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 2: BUILD & PUSH (3-5 min)                               │    │
│  │  ├─ Setup Docker Buildx                                        │    │
│  │  ├─ Login to CloudSmith registry                               │    │
│  │  ├─ Generate image tags (latest, latest-{sha})                 │    │
│  │  ├─ Build Docker image (multi-stage)                           │    │
│  │  │  └─ Stage 1: Install dependencies                           │    │
│  │  │  └─ Stage 2: Copy app, run as non-root                      │    │
│  │  ├─ Run Trivy container scan                                   │    │
│  │  │  └─ Scans: OS packages, app dependencies, secrets           │    │
│  │  └─ Push image to CloudSmith                                   │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                 ↓                                        │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  STAGE 3: DEPLOY TO KUBERNETES (5-10 min)                      │    │
│  │  ├─ Configure AWS credentials (OIDC - no keys!)                │    │
│  │  ├─ Assume IAM role: flask-eks-github-deployer                 │    │
│  │  ├─ Update kubeconfig for EKS cluster                          │    │
│  │  ├─ Create/Update Kubernetes resources:                        │    │
│  │  │  ├─ Namespace (default)                                     │    │
│  │  │  ├─ ImagePullSecret (CloudSmith credentials)                │    │
│  │  │  ├─ ServiceAccount (flask-app-sa)                           │    │
│  │  │  ├─ PersistentVolumeClaims (photos + database)              │    │
│  │  │  ├─ Service (flask-svc)                                     │    │
│  │  │  ├─ Deployment (flask-app) - Rolling update                 │    │
│  │  │  └─ Ingress (flask-alb) - ALB provisioning                  │    │
│  │  ├─ Wait for rollout completion (timeout: 10 min)              │    │
│  │  ├─ Wait for ALB provisioning (timeout: 10 min)                │    │
│  │  └─ Display application URLs                                   │    │
│  └────────────────────────────────────────────────────────────────┘    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      AWS INFRASTRUCTURE (EKS)                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │  VPC (10.0.0.0/16)                                            │      │
│  │  ├─ Public Subnets (10.0.101.0/24, 102, 103) - 3 AZs         │      │
│  │  │  └─ NAT Gateways for outbound traffic                      │      │
│  │  └─ Private Subnets (10.0.1.0/24, 2, 3) - 3 AZs              │      │
│  │     └─ EKS Worker Nodes (no direct internet access)           │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │  EKS Cluster: flask-eks (Kubernetes 1.28)                     │      │
│  │  ├─ Control Plane (Managed by AWS)                            │      │
│  │  ├─ Managed Node Group                                        │      │
│  │  │  ├─ Instance Type: t3.medium                               │      │
│  │  │  ├─ Min: 2, Max: 4, Desired: 2 nodes                       │      │
│  │  │  └─ Auto-scaling enabled                                   │      │
│  │  ├─ Add-ons:                                                  │      │
│  │  │  ├─ CoreDNS (DNS resolution)                               │      │
│  │  │  ├─ VPC-CNI (Pod networking)                               │      │
│  │  │  ├─ kube-proxy (Network proxy)                             │      │
│  │  │  ├─ AWS Load Balancer Controller (ALB management)          │      │
│  │  │  └─ EBS CSI Driver (Persistent volumes)                    │      │
│  │  └─ IRSA Enabled (IAM roles for service accounts)             │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │  Kubernetes Resources (default namespace)                     │      │
│  │                                                                │      │
│  │  ┌────────────────────────────────────────────────┐           │      │
│  │  │  Deployment: flask-app                         │           │      │
│  │  │  ├─ Replicas: 2 pods                           │           │      │
│  │  │  ├─ Image: cloudsmith.io/.../flask-app:latest  │           │      │
│  │  │  ├─ Rolling Update Strategy                    │           │      │
│  │  │  │  ├─ Max Surge: 1                            │           │      │
│  │  │  │  └─ Max Unavailable: 0                      │           │      │
│  │  │  ├─ Resource Limits:                           │           │      │
│  │  │  │  ├─ CPU: 500m, Memory: 512Mi                │           │      │
│  │  │  ├─ Health Checks:                             │           │      │
│  │  │  │  ├─ Liveness: /health every 30s             │           │      │
│  │  │  │  └─ Readiness: /health every 10s            │           │      │
│  │  │  └─ Volume Mounts:                             │           │      │
│  │  │     ├─ /app/static/uploads/photos (photos)    │           │      │
│  │  │     └─ /app/instance (database)                │           │      │
│  │  └────────────────────────────────────────────────┘           │      │
│  │                       ↓                                        │      │
│  │  ┌────────────────────────────────────────────────┐           │      │
│  │  │  Service: flask-svc                            │           │      │
│  │  │  ├─ Type: ClusterIP                            │           │      │
│  │  │  ├─ Port: 5000                                 │           │      │
│  │  │  └─ Selector: app=flask-app                    │           │      │
│  │  └────────────────────────────────────────────────┘           │      │
│  │                       ↓                                        │      │
│  │  ┌────────────────────────────────────────────────┐           │      │
│  │  │  Ingress: flask-alb                            │           │      │
│  │  │  ├─ IngressClass: alb                          │           │      │
│  │  │  ├─ ALB Scheme: internet-facing                │           │      │
│  │  │  ├─ Target Type: ip                            │           │      │
│  │  │  ├─ Health Check: /health                      │           │      │
│  │  │  └─ Routes: /* → flask-svc:5000                │           │      │
│  │  └────────────────────────────────────────────────┘           │      │
│  │                       ↓                                        │      │
│  │  ┌────────────────────────────────────────────────┐           │      │
│  │  │  PersistentVolumeClaims (EBS Volumes)          │           │      │
│  │  │  ├─ persistent-photos-pvc (10Gi)               │           │      │
│  │  │  │  └─ Stores uploaded photos                  │           │      │
│  │  │  └─ persistent-db-pvc (5Gi)                    │           │      │
│  │  │     └─ Stores SQLite database                  │           │      │
│  │  └────────────────────────────────────────────────┘           │      │
│  └──────────────────────────────────────────────────────────────┘      │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │  Application Load Balancer (AWS ALB)                          │      │
│  │  ├─ Public DNS: xxx.us-east-1.elb.amazonaws.com               │      │
│  │  ├─ Listens on: Port 80 (HTTP)                                │      │
│  │  ├─ Health Check: /health every 30s                           │      │
│  │  ├─ Target Group: EKS pod IPs                                 │      │
│  │  └─ Routes traffic to healthy pods                            │      │
│  └──────────────────────────────────────────────────────────────┘      │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                          END USERS                                       │
│  Access application via: http://your-alb-hostname.elb.amazonaws.com     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 💻 Technology Stack

### **Application Layer**
| Technology | Version | Purpose |
|------------|---------|---------|
| Python | 3.11 | Programming language |
| Flask | 3.0+ | Web framework |
| SQLAlchemy | Latest | ORM for database |
| Flask-Migrate | Latest | Database migrations |
| Pillow (PIL) | Latest | Image processing |
| SQLite | 3 | Database |
| Werkzeug | Latest | WSGI utilities |

### **Infrastructure Layer**
| Technology | Version | Purpose |
|------------|---------|---------|
| Terraform | 1.6.0+ | Infrastructure as Code |
| AWS EKS | 1.28 | Kubernetes cluster |
| AWS VPC | - | Network isolation |
| AWS ALB | - | Load balancing |
| AWS EBS | - | Persistent storage |
| AWS IAM | - | Access management |

### **Container & Orchestration**
| Technology | Version | Purpose |
|------------|---------|---------|
| Docker | Latest | Containerization |
| Kubernetes | 1.28 | Container orchestration |
| kubectl | Latest | K8s CLI |
| Helm | 2.11+ | Package manager |

### **CI/CD & Security**
| Technology | Version | Purpose |
|------------|---------|---------|
| GitHub Actions | - | CI/CD pipeline |
| Bandit | Latest | Python SAST |
| Safety | Latest | Dependency scanning |
| Trivy | Latest | Container scanning |
| CloudSmith | - | Artifact registry |

---

## 🔄 Complete Flow Explanation

### **Phase 1: Development Phase**

```
1. Developer writes code locally
   ├─ Modifies app.py (Flask application)
   ├─ Updates requirements.txt (dependencies)
   ├─ Changes Dockerfile (container config)
   └─ Updates k8s/*.yaml (Kubernetes manifests)

2. Local testing
   ├─ python app.py (run locally)
   ├─ docker build -t flask-app:test . (test container)
   └─ docker run -p 5000:5000 flask-app:test

3. Commit and push to GitHub
   ├─ git add .
   ├─ git commit -m "Add new feature"
   └─ git push origin main
```

### **Phase 2: CI/CD Pipeline (Automated)**

#### **Trigger Conditions:**
- Push to `main`, `develop`, or `photo-upload-app` branches
- Changes to: `app.py`, `requirements.txt`, `Dockerfile`, `k8s/**`, `.github/workflows/**`
- Manual workflow dispatch

#### **Pipeline Execution:**

**Job 1: Security Scanning (Duration: ~2 minutes)**
```yaml
Steps:
1. actions/checkout@v4
   └─ Clones repository code

2. actions/setup-python@v4
   └─ Installs Python 3.11

3. Install dependencies
   └─ pip install -r requirements.txt
   └─ pip install bandit[toml] safety

4. Run Bandit (SAST)
   Command: bandit -r . -ll -f json -o bandit-report.json
   Checks:
   ├─ Hardcoded passwords/secrets
   ├─ SQL injection vulnerabilities
   ├─ Use of insecure functions (eval, exec)
   ├─ Weak cryptography
   └─ Security misconfigurations
   
   Severity Levels:
   ├─ HIGH: Critical security issues
   ├─ MEDIUM: Potential vulnerabilities
   └─ LOW: Best practice violations

5. Run Safety (Dependency Scan)
   Command: safety scan --json > safety-report.json
   Checks:
   ├─ Known CVEs in Python packages
   ├─ Outdated dependencies
   └─ Security advisories from PyPI

6. Upload security reports
   └─ Artifacts available for 90 days

7. Check results
   └─ Fail pipeline if HIGH severity issues found
```

**Job 2: Build & Push (Duration: ~3-5 minutes)**
```yaml
Steps:
1. Setup Docker Buildx
   └─ Enables multi-platform builds

2. Login to CloudSmith
   Registry: docker.cloudsmith.io
   Credentials: From GitHub secrets

3. Generate image tags
   ├─ latest
   ├─ latest-{git-sha-7-chars}
   └─ Example: latest-a1b2c3d

4. Build Docker image (Multi-stage)
   
   Stage 1 (builder):
   ├─ FROM python:3.11-slim
   ├─ WORKDIR /app
   ├─ COPY requirements.txt
   ├─ RUN pip install --no-cache-dir -r requirements.txt
   └─ Creates: /usr/local/lib/python3.11/site-packages
   
   Stage 2 (runtime):
   ├─ FROM python:3.11-slim
   ├─ COPY --from=builder /usr/local/lib/python3.11/site-packages
   ├─ COPY app.py, templates/, static/
   ├─ Create non-root user: appuser
   ├─ USER appuser
   ├─ EXPOSE 5000
   └─ CMD ["python", "app.py"]
   
   Benefits:
   ├─ Smaller image size (~150MB)
   ├─ No build tools in final image
   └─ Enhanced security

5. Run Trivy container scan
   Command: trivy image --format table --severity CRITICAL,HIGH
   Scans:
   ├─ OS packages (Debian packages)
   ├─ Python packages (pip)
   ├─ Known vulnerabilities (CVE database)
   ├─ Misconfigurations
   └─ Secrets in image layers
   
   Exit Code: 0 (report only, don't fail)

6. Push to CloudSmith
   ├─ docker push docker.cloudsmith.io/.../flask-app:latest
   └─ docker push docker.cloudsmith.io/.../flask-app:latest-{sha}

7. Output image tag
   └─ Used by deployment job
```

**Job 3: Deploy to Kubernetes (Duration: ~5-10 minutes)**
```yaml
Steps:
1. Configure AWS credentials (OIDC)
   Action: aws-actions/configure-aws-credentials@v4
   
   Process:
   ├─ Request OIDC token from GitHub
   │  Token contains:
   │  ├─ Repository: yuvanreddy/flask-app-update
   │  ├─ Branch: refs/heads/main
   │  ├─ Commit SHA: abc123...
   │  └─ Audience: sts.amazonaws.com
   │
   ├─ Send token to AWS STS
   │  API: AssumeRoleWithWebIdentity
   │  Role ARN: arn:aws:iam::816069153839:role/flask-eks-github-deployer
   │
   ├─ AWS validates token
   │  Checks:
   │  ├─ OIDC provider exists
   │  ├─ Audience matches: sts.amazonaws.com
   │  └─ Subject matches: repo:yuvanreddy/flask-app-update:*
   │
   └─ Returns temporary credentials
      ├─ Access Key ID
      ├─ Secret Access Key
      ├─ Session Token
      └─ Expiration: 1 hour

2. Update kubeconfig
   Command: aws eks update-kubeconfig --name flask-eks --region us-east-1
   Creates: ~/.kube/config with cluster credentials

3. Ensure namespace exists
   Command: kubectl get ns default || kubectl create ns default

4. Create/Update imagePullSecret
   Purpose: Pull images from private CloudSmith registry
   
   Command:
   kubectl create secret docker-registry cloudsmith-regcred \
     --namespace default \
     --docker-server=docker.cloudsmith.io \
     --docker-username=$CLOUDSMITH_USERNAME \
     --docker-password=$CLOUDSMITH_API_KEY \
     --dry-run=client -o yaml | kubectl apply -f -

5. Create ServiceAccount
   Purpose: Associate imagePullSecret with pods
   
   Manifest:
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: flask-app-sa
     namespace: default
   imagePullSecrets:
   - name: cloudsmith-regcred

6. Apply PersistentVolumeClaims
   File: k8s/persistent-storage.yaml
   
   Creates:
   ├─ persistent-photos-pvc (10Gi)
   │  ├─ StorageClass: gp2 (AWS EBS)
   │  ├─ Access Mode: ReadWriteOnce
   │  └─ Mounted at: /app/static/uploads/photos
   │
   └─ persistent-db-pvc (5Gi)
      ├─ StorageClass: gp2 (AWS EBS)
      ├─ Access Mode: ReadWriteOnce
      └─ Mounted at: /app/instance

7. Apply/Update Service
   File: k8s/service.yml
   
   Manifest:
   apiVersion: v1
   kind: Service
   metadata:
     name: flask-svc
   spec:
     type: ClusterIP
     selector:
       app: flask-app
     ports:
     - port: 5000
       targetPort: 5000

8. Deploy application
   File: k8s/deployment.yaml
   
   Process:
   ├─ Check if deployment exists
   │  └─ kubectl get deploy flask-app -n default
   │
   ├─ Apply deployment manifest
   │  └─ kubectl apply -f k8s/deployment.yaml
   │
   ├─ Update image tag
   │  └─ kubectl set image deployment/flask-app \
   │       flask=docker.cloudsmith.io/.../flask-app:latest-{sha}
   │
   ├─ Add deployment annotation (force rollout)
   │  └─ kubectl patch deployment flask-app \
   │       -p '{"spec":{"template":{"metadata":{"annotations":{"deployedAt":"'$(date +%s)'"}}}}}'
   │
   └─ Wait for rollout
      └─ kubectl rollout status deployment/flask-app --timeout=600s
   
   Rolling Update Process:
   ├─ Current: 2 pods running (v1)
   ├─ Create 1 new pod (v2)
   ├─ Wait for readiness probe to pass
   ├─ Terminate 1 old pod (v1)
   ├─ Create 1 new pod (v2)
   ├─ Wait for readiness probe to pass
   ├─ Terminate last old pod (v1)
   └─ Final: 2 pods running (v2)
   
   Zero Downtime Guaranteed:
   ├─ maxSurge: 1 (max 3 pods during update)
   └─ maxUnavailable: 0 (always 2 pods running)

9. Apply/Update Ingress
   File: k8s/ingress.yml
   
   Manifest:
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: flask-alb
     annotations:
       alb.ingress.kubernetes.io/scheme: internet-facing
       alb.ingress.kubernetes.io/target-type: ip
       alb.ingress.kubernetes.io/healthcheck-path: /health
   spec:
     ingressClassName: alb
     rules:
     - http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: flask-svc
               port:
                 number: 5000
   
   ALB Controller Actions:
   ├─ Detects new Ingress resource
   ├─ Creates AWS Application Load Balancer
   ├─ Configures target group with pod IPs
   ├─ Sets up health checks (/health)
   ├─ Configures listeners (port 80)
   └─ Updates Ingress status with ALB DNS

10. Wait for ALB provisioning
    Duration: Up to 10 minutes
    
    Loop:
    ├─ kubectl get ingress flask-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    ├─ Check every 10 seconds
    └─ Timeout after 60 attempts (10 minutes)

11. Display application URLs
    Output:
    ├─ Main App: http://{alb-hostname}/
    ├─ Health Check: http://{alb-hostname}/health
    └─ Upload Page: http://{alb-hostname}/upload
```

### **Phase 3: Infrastructure Management (Terraform)**

**Workflow:** `terraform-apply-destroy.yml`  
**Trigger:** Manual workflow dispatch only

**Terraform Resources Created:**

```hcl
1. VPC Module (terraform-aws-modules/vpc/aws)
   ├─ VPC: 10.0.0.0/16
   ├─ Public Subnets: 10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24
   ├─ Private Subnets: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
   ├─ Internet Gateway (for public subnets)
   ├─ NAT Gateways (for private subnet internet access)
   └─ Route Tables

2. EKS Cluster Module (terraform-aws-modules/eks/aws)
   ├─ Control Plane (managed by AWS)
   ├─ Managed Node Group
   │  ├─ Instance Type: t3.medium
   │  ├─ Min: 2, Max: 4, Desired: 2
   │  ├─ Disk Size: 50GB
   │  └─ AMI: Amazon Linux 2 EKS Optimized
   ├─ Cluster Add-ons
   │  ├─ coredns (DNS)
   │  ├─ kube-proxy (networking)
   │  ├─ vpc-cni (pod networking)
   │  └─ aws-ebs-csi-driver (persistent volumes)
   └─ IRSA Enabled

3. KMS Key
   ├─ Purpose: EKS secret encryption
   ├─ Key Rotation: Enabled
   └─ Deletion Window: 7 days

4. IAM Roles
   ├─ flask-eks-github-deployer
   │  ├─ Trust Policy: GitHub OIDC
   │  ├─ Permissions: EKS describe, ECR pull
   │  └─ Access Policy: AmazonEKSClusterAdminPolicy
   │
   ├─ flask-eks-alb-controller-role
   │  ├─ Trust Policy: EKS OIDC (IRSA)
   │  ├─ Service Account: kube-system:aws-load-balancer-controller
   │  └─ Permissions: ALB/ELB management
   │
   └─ flask-eks-ebs-csi-driver-role
      ├─ Trust Policy: EKS OIDC (IRSA)
      ├─ Service Account: kube-system:ebs-csi-controller-sa
      └─ Permissions: EBS volume management

5. EKS Access Entries
   ├─ GitHub Actions Role
   │  └─ Policy: AmazonEKSClusterAdminPolicy
   └─ IAM User: Deeraj
      └─ Policy: AmazonEKSClusterAdminPolicy

6. ALB Controller (Helm)
   ├─ Namespace: kube-system
   ├─ Service Account: aws-load-balancer-controller
   ├─ IAM Role: flask-eks-alb-controller-role (IRSA)
   └─ Manages: ALB, Target Groups, Listeners

7. EBS CSI Driver
   ├─ Namespace: kube-system
   ├─ Service Account: ebs-csi-controller-sa
   ├─ IAM Role: flask-eks-ebs-csi-driver-role (IRSA)
   └─ Manages: EBS volumes for PVCs
```

**Terraform Execution:**
```bash
Duration: 15-20 minutes

Steps:
1. terraform init
   ├─ Initialize S3 backend
   │  Bucket: terraform-state-816069153839
   │  Key: eks/terraform.tfstate
   │  Region: us-east-1
   │  DynamoDB Table: terraform-state-lock
   └─ Download provider plugins

2. terraform validate
   └─ Validate syntax and configuration

3. terraform plan
   └─ Show resources to be created/modified/destroyed

4. terraform apply
   Creates:
   ├─ VPC and subnets (2 min)
   ├─ EKS control plane (10 min)
   ├─ Node group (5 min)
   ├─ IAM roles (1 min)
   ├─ ALB controller (2 min)
   └─ EBS CSI driver (1 min)
```

---

## 📱 Application Flow

### **User Journey: Photo Upload**

```
1. User opens browser
   └─ Navigates to: http://your-alb-hostname.elb.amazonaws.com/

2. ALB receives request
   ├─ Checks health of backend pods
   ├─ Selects healthy pod (round-robin)
   └─ Forwards request to pod IP:5000

3. Flask app handles request
   Route: @app.route('/')
   Function: index()
   
   Process:
   ├─ Query database: Photo.query.order_by(Photo.upload_date.desc()).all()
   ├─ Render template: render_template('index.html', photos=photos_list)
   └─ Return HTML response

4. User sees photo gallery
   ├─ Displays all uploaded photos (thumbnails)
   ├─ Shows upload date, file size
   └─ "Upload Photo" button

5. User clicks "Upload Photo"
   └─ Navigates to: /upload

6. Upload form displayed
   Fields:
   ├─ File input (accept: image/*)
   └─ Description textarea (optional)

7. User selects photo and submits
   POST /upload
   Content-Type: multipart/form-data
   
   Request Body:
   ├─ photo: <binary file data>
   └─ description: "My vacation photo"

8. Flask processes upload
   Route: @app.route('/upload', methods=['POST'])
   Function: upload()
   
   Steps:
   ├─ Validate file exists
   │  └─ if 'photo' not in request.files: return error
   │
   ├─ Validate file type
   │  Allowed: .png, .jpg, .jpeg, .gif
   │  └─ if not allowed_file(filename): return error
   │
   ├─ Generate unique filename
   │  └─ unique_filename = f"{uuid.uuid4()}_{secure_filename(filename)}"
   │  Example: "a1b2c3d4-e5f6-7890-abcd-ef1234567890_vacation.jpg"
   │
   ├─ Save file to persistent storage
   │  Path: /app/static/uploads/photos/{unique_filename}
   │  └─ file.save(file_path)
   │
   ├─ Create thumbnail
   │  Function: create_thumbnail(file_path, photo_id)
   │  
   │  Process:
   │  ├─ Open image with PIL: Image.open(file_path)
   │  ├─ Convert to RGB (for JPEG compatibility)
   │  ├─ Resize to max 300x300 (maintains aspect ratio)
   │  ├─ Save as JPEG: {photo_id}_thumb.jpg
   │  └─ Path: /app/static/thumbnails/{photo_id}_thumb.jpg
   │
   ├─ Store metadata in database
   │  Table: photo
   │  
   │  Record:
   │  ├─ id: UUID (primary key)
   │  ├─ filename: unique_filename
   │  ├─ original_filename: vacation.jpg
   │  ├─ file_size: 2457600 (bytes)
   │  ├─ mime_type: image/jpeg
   │  ├─ upload_date: 2025-10-09 09:00:00
   │  └─ description: "My vacation photo"
   │  
   │  Commands:
   │  ├─ photo = Photo(...)
   │  ├─ db.session.add(photo)
   │  └─ db.session.commit()
   │
   └─ Redirect to photo view page
      └─ return redirect(url_for('view_photo', photo_id=photo.id))

9. User sees uploaded photo
   Route: /photo/{photo_id}
   
   Display:
   ├─ Full-size image
   ├─ Metadata (filename, size, date, description)
   ├─ "Delete" button
   └─ "Back to Gallery" link

10. Photo persists across pod restarts
    ├─ Photo file: Stored on EBS volume (persistent-photos-pvc)
    ├─ Thumbnail: Stored on EBS volume (persistent-photos-pvc)
    └─ Metadata: Stored in SQLite on EBS volume (persistent-db-pvc)
```

### **Database Schema**

```sql
CREATE TABLE photo (
    id VARCHAR(36) PRIMARY KEY,           -- UUID
    filename VARCHAR(255) NOT NULL,       -- Unique filename
    original_filename VARCHAR(255) NOT NULL,  -- Original name
    file_size INTEGER NOT NULL,           -- Size in bytes
    mime_type VARCHAR(100) NOT NULL,      -- image/jpeg, etc.
    upload_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    description TEXT                      -- Optional description
);

-- Example Record:
INSERT INTO photo VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890_vacation.jpg',
    'vacation.jpg',
    2457600,
    'image/jpeg',
    '2025-10-09 09:00:00',
    'My vacation photo'
);
```

### **API Endpoints**

```
GET /
├─ Purpose: Main page with photo gallery
├─ Response: HTML (index.html)
└─ Shows: All photos with thumbnails

GET /upload
├─ Purpose: Display upload form
├─ Response: HTML (upload.html)
└─ Form: File input + description

POST /upload
├─ Purpose: Handle photo upload
├─ Request: multipart/form-data
├─ Response: Redirect to /photo/{id}
└─ Process: Save file, create thumbnail, store metadata

GET /photo/{photo_id}
├─ Purpose: View individual photo
├─ Response: HTML (view_photo.html)
└─ Shows: Full image + metadata

POST /photo/{photo_id}/delete
├─ Purpose: Delete photo
├─ Response: Redirect to /
└─ Actions: Delete file, thumbnail, database record

GET /photos
├─ Purpose: API endpoint (list all photos)
├─ Response: JSON
└─ Format: {"photos": [...], "total": 10}

GET /uploads/photos/{filename}
├─ Purpose: Serve uploaded photo files
├─ Response: Image binary
└─ Headers: Content-Type: image/jpeg

GET /thumbnail/{photo_id}
├─ Purpose: Serve thumbnail images
├─ Response: Image binary (JPEG)
└─ Fallback: Original image if thumbnail missing

GET /health
├─ Purpose: Health check for monitoring
├─ Response: JSON {"status": "healthy", "service": "photo-gallery"}
└─ Status Code: 200 OK
```

---

## 🔐 Security & Authentication

### **OIDC Authentication Flow (GitHub → AWS)**

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions Workflow Starts                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Step: Configure AWS Credentials (OIDC)                     │
│  Action: aws-actions/configure-aws-credentials@v4           │
│                                                              │
│  Inputs:                                                     │
│  ├─ role-to-assume: arn:aws:iam::816069153839:role/...      │
│  ├─ aws-region: us-east-1                                   │
│  └─ role-session-name: github-actions-terraform             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  GitHub Issues OIDC Token                                   │
│                                                              │
│  Token Claims (JWT):                                        │
│  {                                                           │
│    "iss": "https://token.actions.githubusercontent.com",    │
│    "aud": "sts.amazonaws.com",                              │
│    "sub": "repo:yuvanreddy/flask-app-update:ref:refs/heads/main",│
│    "repository": "yuvanreddy/flask-app-update",             │
│    "ref": "refs/heads/main",                                │
│    "sha": "abc123...",                                      │
│    "workflow": "Build, Push & Deploy Flask App",           │
│    "actor": "yuvanreddy",                                   │
│    "exp": 1696848000                                        │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  AWS STS API Call                                           │
│  API: AssumeRoleWithWebIdentity                             │
│                                                              │
│  Request:                                                    │
│  ├─ RoleArn: arn:aws:iam::816069153839:role/flask-eks-...   │
│  ├─ WebIdentityToken: <JWT token from GitHub>              │
│  ├─ RoleSessionName: github-actions-terraform              │
│  └─ DurationSeconds: 3600 (1 hour)                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  AWS IAM Validation                                         │
│                                                              │
│  Checks:                                                     │
│  1. OIDC Provider exists                                    │
│     └─ arn:aws:iam::816069153839:oidc-provider/token.actions.githubusercontent.com│
│                                                              │
│  2. Token signature valid                                   │
│     └─ Verify with GitHub's public key                      │
│                                                              │
│  3. Token not expired                                       │
│     └─ Check exp claim                                      │
│                                                              │
│  4. Audience matches                                        │
│     └─ "aud": "sts.amazonaws.com" ✓                         │
│                                                              │
│  5. Subject matches trust policy                            │
│     Trust Policy Condition:                                 │
│     "StringLike": {                                         │
│       "token.actions.githubusercontent.com:sub":            │
│         "repo:yuvanreddy/flask-app-update:*"                │
│     }                                                        │
│     Token sub: "repo:yuvanreddy/flask-app-update:ref:refs/heads/main" ✓│
│                                                              │
│  6. Role permissions check                                  │
│     └─ Role has required policies attached                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓ (All checks pass)
┌─────────────────────────────────────────────────────────────┐
│  AWS STS Returns Temporary Credentials                      │
│                                                              │
│  Response:                                                   │
│  {                                                           │
│    "Credentials": {                                         │
│      "AccessKeyId": "ASIAXXX...",                           │
│      "SecretAccessKey": "wJalrXXX...",                      │
│      "SessionToken": "FwoGZXIvYXdzEXXX...",                 │
│      "Expiration": "2025-10-09T10:00:00Z"                   │
│    },                                                        │
│    "AssumedRoleUser": {                                     │
│      "AssumedRoleId": "AROAXX:github-actions-terraform",    │
│      "Arn": "arn:aws:sts::816069153839:assumed-role/..."    │
│    }                                                         │
│  }                                                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions Sets Environment Variables                  │
│                                                              │
│  export AWS_ACCESS_KEY_ID="ASIAXXX..."                      │
│  export AWS_SECRET_ACCESS_KEY="wJalrXXX..."                 │
│  export AWS_SESSION_TOKEN="FwoGZXIvYXdzEXXX..."             │
│  export AWS_REGION="us-east-1"                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
┌─────────────────────────────────────────────────────────────┐
│  Subsequent AWS API Calls Use Temporary Credentials         │
│                                                              │
│  Examples:                                                   │
│  ├─ aws eks update-kubeconfig --name flask-eks              │
│  ├─ kubectl get pods                                        │
│  ├─ terraform apply                                         │
│  └─ aws sts get-caller-identity                             │
│                                                              │
│  All authenticated as:                                      │
│  arn:aws:sts::816069153839:assumed-role/flask-eks-github-deployer/...│
└─────────────────────────────────────────────────────────────┘
```

### **Benefits of OIDC vs. Long-Lived Credentials**

| Aspect | OIDC (Current) | Long-Lived Keys (Old Way) |
|--------|----------------|---------------------------|
| **Credential Storage** | No credentials stored | Keys in GitHub Secrets |
| **Rotation** | Automatic (every workflow run) | Manual rotation required |
| **Expiration** | 1 hour (configurable) | Never expires |
| **Compromise Risk** | Low (short-lived) | High (permanent access) |
| **Audit Trail** | CloudTrail shows exact workflow | Only shows IAM user |
| **Revocation** | Update trust policy | Delete/rotate keys |
| **Granularity** | Per-repo, per-branch | Per-IAM user |

### **Security Scanning Details**

#### **1. Bandit (SAST - Static Application Security Testing)**

```yaml
Purpose: Analyze Python source code for security issues

Configuration: .bandit file
[bandit]
exclude = /test,/tests,/venv,/.venv,/env
skips = B104  # Allow 0.0.0.0 binding (required for containers)

Common Issues Detected:
├─ B201: Flask app with debug=True (production risk)
├─ B301: Pickle usage (code injection risk)
├─ B303: MD5/SHA1 usage (weak cryptography)
├─ B311: Random module (not cryptographically secure)
├─ B501: Requests without cert verification
├─ B601: Shell injection via paramiko
├─ B602: Shell injection via subprocess
└─ B608: SQL injection via string formatting

Severity Levels:
├─ HIGH: Critical security vulnerabilities
│  └─ Action: Pipeline fails
├─ MEDIUM: Potential security issues
│  └─ Action: Warning, pipeline continues
└─ LOW: Best practice violations
   └─ Action: Informational only

Report Format:
{
  "metrics": {
    "total": {
      "ISSUE_HIGH": 0,
      "ISSUE_MEDIUM": 2,
      "ISSUE_LOW": 5
    }
  },
  "results": [
    {
      "code": "app.run(host='0.0.0.0', debug=True)",
      "filename": "app.py",
      "issue_severity": "MEDIUM",
      "issue_text": "Flask app run with debug=True",
      "line_number": 232,
      "test_id": "B201"
    }
  ]
}
```

#### **2. Safety (Dependency Vulnerability Scanning)**

```yaml
Purpose: Check Python packages for known vulnerabilities

Command: safety scan --json

Database: PyUp.io vulnerability database (40,000+ vulnerabilities)

Checks:
├─ Known CVEs in installed packages
├─ Security advisories from PyPI
├─ Outdated packages with security fixes
└─ Transitive dependencies

Example Output:
{
  "vulnerabilities": [
    {
      "package": "flask",
      "installed_version": "2.0.1",
      "affected_versions": "<2.0.2",
      "vulnerability": "CVE-2021-12345",
      "severity": "HIGH",
      "description": "Flask vulnerable to XSS in error pages",
      "fix": "Upgrade to flask>=2.0.2"
    }
  ]
}

Action Items:
├─ Update requirements.txt with fixed versions
├─ Run: pip install --upgrade flask
└─ Re-run pipeline
```

#### **3. Trivy (Container Image Scanning)**

```yaml
Purpose: Scan Docker images for vulnerabilities and misconfigurations

Command: trivy image --format table --severity CRITICAL,HIGH

Scans:
├─ OS Packages (Debian/Ubuntu packages)
│  Example: libc6, openssl, zlib1g
│
├─ Application Dependencies (Python packages)
│  Example: flask, werkzeug, jinja2
│
├─ Known Vulnerabilities (CVE database)
│  Sources: NVD, Red Hat, Debian Security, etc.
│
├─ Misconfigurations
│  ├─ Running as root user
│  ├─ Exposed secrets in ENV
│  └─ Insecure file permissions
│
└─ Secrets Detection
   ├─ AWS access keys
   ├─ API tokens
   └─ Private keys

Example Output:
┌──────────────────────────────────────────────────────────┐
│ python:3.11-slim (debian 12.1)                           │
├──────────────────────────────────────────────────────────┤
│ Total: 15 (CRITICAL: 2, HIGH: 13)                        │
├──────────────────────────────────────────────────────────┤
│ Library  │ Vulnerability │ Severity │ Installed │ Fixed  │
├──────────┼───────────────┼──────────┼───────────┼────────┤
│ openssl  │ CVE-2023-1234 │ CRITICAL │ 3.0.9     │ 3.0.10 │
│ libc6    │ CVE-2023-5678 │ HIGH     │ 2.36-1    │ 2.36-2 │
└──────────────────────────────────────────────────────────┘

Action Items:
├─ Update base image: FROM python:3.11-slim → python:3.11-slim-bookworm
├─ Add: RUN apt-get update && apt-get upgrade -y
└─ Re-build and re-scan
```

---

## 🚀 Deployment Process

### **Zero-Downtime Rolling Update**

```
Initial State:
┌────────────────────────────────────────────────────────┐
│ Deployment: flask-app (v1.0)                           │
│ Replicas: 2                                            │
│                                                         │
│ ┌─────────────┐          ┌─────────────┐              │
│ │   Pod 1     │          │   Pod 2     │              │
│ │  v1.0       │          │  v1.0       │              │
│ │  Ready ✓    │          │  Ready ✓    │              │
│ └─────────────┘          └─────────────┘              │
│                                                         │
│ Service: flask-svc                                     │
│ ├─ Endpoint: Pod 1 IP:5000                            │
│ └─ Endpoint: Pod 2 IP:5000                            │
│                                                         │
│ ALB Target Group:                                      │
│ ├─ Target: Pod 1 IP:5000 (healthy)                    │
│ └─ Target: Pod 2 IP:5000 (healthy)                    │
└────────────────────────────────────────────────────────┘

Deployment Triggered:
kubectl set image deployment/flask-app flask=...flask-app:v1.1

Step 1: Create New Pod (maxSurge: 1)
┌────────────────────────────────────────────────────────┐
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│ │   Pod 1     │  │   Pod 2     │  │   Pod 3     │     │
│ │  v1.0       │  │  v1.0       │  │  v1.1       │     │
│ │  Ready ✓    │  │  Ready ✓    │  │  Creating...│     │
│ └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│ Actions:                                               │
│ ├─ Pull image: flask-app:v1.1                         │
│ ├─ Create container                                   │
│ ├─ Mount volumes                                      │
│ └─ Start application                                  │
└────────────────────────────────────────────────────────┘

Step 2: Wait for Readiness Probe
┌────────────────────────────────────────────────────────┐
│ Readiness Probe Configuration:                         │
│ ├─ HTTP GET /health                                    │
│ ├─ Initial Delay: 10s                                  │
│ ├─ Period: 10s                                         │
│ ├─ Success Threshold: 1                                │
│ └─ Failure Threshold: 3                                │
│                                                         │
│ Probe Attempts:                                        │
│ ├─ Attempt 1 (10s): GET /health → 200 OK ✓            │
│ └─ Pod 3 marked as Ready                               │
│                                                         │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│ │   Pod 1     │  │   Pod 2     │  │   Pod 3     │     │
│ │  v1.0       │  │  v1.0       │  │  v1.1       │     │
│ │  Ready ✓    │  │  Ready ✓    │  │  Ready ✓    │     │
│ └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│ Service Updates:                                       │
│ ├─ Add endpoint: Pod 3 IP:5000                        │
│ └─ Now routing to: Pod 1, Pod 2, Pod 3                │
│                                                         │
│ ALB Updates:                                           │
│ ├─ Register target: Pod 3 IP:5000                     │
│ ├─ Health check: /health → 200 OK                     │
│ └─ Target marked healthy                              │
└────────────────────────────────────────────────────────┘

Step 3: Terminate Old Pod (maxUnavailable: 0)
┌────────────────────────────────────────────────────────┐
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│ │   Pod 1     │  │   Pod 2     │  │   Pod 3     │     │
│ │  v1.0       │  │  v1.0       │  │  v1.1       │     │
│ │  Terminating│  │  Ready ✓    │  │  Ready ✓    │     │
│ └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│ Termination Process:                                   │
│ ├─ Send SIGTERM to Pod 1                              │
│ ├─ Grace period: 30 seconds                           │
│ ├─ Application cleanup (close DB connections, etc.)   │
│ ├─ Send SIGKILL if not stopped                        │
│ └─ Remove pod                                          │
│                                                         │
│ Service Updates:                                       │
│ ├─ Remove endpoint: Pod 1 IP:5000                     │
│ └─ Now routing to: Pod 2, Pod 3                       │
│                                                         │
│ ALB Updates:                                           │
│ ├─ Deregister target: Pod 1 IP:5000                   │
│ └─ Stop routing traffic to Pod 1                      │
└────────────────────────────────────────────────────────┘

Step 4: Create Second New Pod
┌────────────────────────────────────────────────────────┐
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│ │   Pod 4     │  │   Pod 2     │  │   Pod 3     │     │
│ │  v1.1       │  │  v1.0       │  │  v1.1       │     │
│ │  Creating...│  │  Ready ✓    │  │  Ready ✓    │     │
│ └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│ Same process as Step 1-2                               │
└────────────────────────────────────────────────────────┘

Step 5: Wait for Readiness, Terminate Last Old Pod
┌────────────────────────────────────────────────────────┐
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│ │   Pod 4     │  │   Pod 2     │  │   Pod 3     │     │
│ │  v1.1       │  │  v1.0       │  │  v1.1       │     │
│ │  Ready ✓    │  │  Terminating│  │  Ready ✓    │     │
│ └─────────────┘  └─────────────┘  └─────────────┘     │
└────────────────────────────────────────────────────────┘

Final State:
┌────────────────────────────────────────────────────────┐
│ Deployment: flask-app (v1.1)                           │
│ Replicas: 2                                            │
│                                                         │
│ ┌─────────────┐          ┌─────────────┐              │
│ │   Pod 4     │          │   Pod 3     │              │
│ │  v1.1       │          │  v1.1       │              │
│ │  Ready ✓    │          │  Ready ✓    │              │
│ └─────────────┘          └─────────────┘              │
│                                                         │
│ Service: flask-svc                                     │
│ ├─ Endpoint: Pod 4 IP:5000                            │
│ └─ Endpoint: Pod 3 IP:5000                            │
│                                                         │
│ ALB Target Group:                                      │
│ ├─ Target: Pod 4 IP:5000 (healthy)                    │
│ └─ Target: Pod 3 IP:5000 (healthy)                    │
│                                                         │
│ Rollout Status: Successfully rolled out                │
│ Duration: ~2-3 minutes                                 │
└────────────────────────────────────────────────────────┘

Key Points:
✅ Zero downtime - always 2 pods running
✅ Gradual rollout - one pod at a time
✅ Health checks - only route to healthy pods
✅ Automatic rollback - if new pods fail health checks
✅ Traffic continuity - ALB always has healthy targets
```

---

## 📊 Monitoring & Health Checks

### **Health Check Layers**

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Application Health Check                          │
│  Endpoint: GET /health                                      │
│                                                              │
│  Response:                                                   │
│  {                                                           │
│    "status": "healthy",                                     │
│    "service": "photo-gallery",                              │
│    "timestamp": "2025-10-09T09:00:00Z"                      │
│  }                                                           │
│                                                              │
│  Status Code: 200 OK                                        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Kubernetes Liveness Probe                         │
│  Purpose: Restart pod if application is unhealthy           │
│                                                              │
│  Configuration:                                              │
│  livenessProbe:                                             │
│    httpGet:                                                 │
│      path: /health                                          │
│      port: 5000                                             │
│    initialDelaySeconds: 30                                  │
│    periodSeconds: 30                                        │
│    timeoutSeconds: 3                                        │
│    failureThreshold: 3                                      │
│                                                              │
│  Behavior:                                                   │
│  ├─ Wait 30s after container starts                        │
│  ├─ Check /health every 30s                                │
│  ├─ Timeout after 3s                                       │
│  ├─ Fail after 3 consecutive failures                      │
│  └─ Action: Restart container                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Kubernetes Readiness Probe                        │
│  Purpose: Control traffic routing to pod                    │
│                                                              │
│  Configuration:                                              │
│  readinessProbe:                                            │
│    httpGet:                                                 │
│      path: /health                                          │
│      port: 5000                                             │
│    initialDelaySeconds: 10                                  │
│    periodSeconds: 10                                        │
│    timeoutSeconds: 3                                        │
│    successThreshold: 1                                      │
│    failureThreshold: 3                                      │
│                                                              │
│  Behavior:                                                   │
│  ├─ Wait 10s after container starts                        │
│  ├─ Check /health every 10s                                │
│  ├─ Timeout after 3s                                       │
│  ├─ Ready after 1 success                                  │
│  ├─ Not ready after 3 consecutive failures                 │
│  └─ Action: Remove from Service endpoints                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 4: ALB Health Check                                  │
│  Purpose: Route traffic only to healthy targets             │
│                                                              │
│  Configuration (from Ingress annotations):                   │
│  alb.ingress.kubernetes.io/healthcheck-path: /health        │
│  alb.ingress.kubernetes.io/healthcheck-interval-seconds: 30 │
│  alb.ingress.kubernetes.io/healthcheck-timeout-seconds: 5   │
│  alb.ingress.kubernetes.io/healthy-threshold-count: 2       │
│  alb.ingress.kubernetes.io/unhealthy-threshold-count: 2     │
│                                                              │
│  Behavior:                                                   │
│  ├─ Check /health every 30s                                │
│  ├─ Timeout after 5s                                       │
│  ├─ Healthy after 2 consecutive successes                  │
│  ├─ Unhealthy after 2 consecutive failures                 │
│  └─ Action: Stop routing traffic to unhealthy targets      │
│                                                              │
│  Target Group Status:                                       │
│  ├─ Target: 10.0.1.45:5000 (healthy)                       │
│  └─ Target: 10.0.2.78:5000 (healthy)                       │
└─────────────────────────────────────────────────────────────┘
```

### **Monitoring Commands**

```bash
# Check deployment status
kubectl get deployments -n default
kubectl describe deployment flask-app -n default

# Check pod status
kubectl get pods -n default -l app=flask-app
kubectl describe pod <pod-name> -n default

# View pod logs
kubectl logs -f <pod-name> -n default
kubectl logs --tail=100 -l app=flask-app -n default

# Check service endpoints
kubectl get endpoints flask-svc -n default

# Check ingress status
kubectl get ingress flask-alb -n default
kubectl describe ingress flask-alb -n default

# Check ALB target health (AWS CLI)
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Check persistent volumes
kubectl get pvc -n default
kubectl describe pvc persistent-photos-pvc -n default

# View events
kubectl get events -n default --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n default
kubectl top nodes
```

---

## 🔧 Troubleshooting Guide

### **Common Issues and Solutions**

#### **Issue 1: OIDC Authentication Fails**

```
Error: Not authorized to perform sts:AssumeRoleWithWebIdentity

Root Causes:
1. Trust policy mismatch
2. OIDC provider doesn't exist
3. Wrong repository name in trust policy
4. Token audience mismatch

Solution:
1. Verify OIDC provider exists:
   aws iam list-open-id-connect-providers

2. Check trust policy:
   aws iam get-role --role-name flask-eks-github-deployer \
     --query "Role.AssumeRolePolicyDocument"

3. Verify trust policy has correct repository:
   "token.actions.githubusercontent.com:sub": "repo:yuvanreddy/flask-app-update:*"
   
   ❌ Wrong: "repo:flask-app-update:*" (missing owner)
   ✅ Correct: "repo:yuvanreddy/flask-app-update:*"

4. Update trust policy:
   aws iam update-assume-role-policy \
     --role-name flask-eks-github-deployer \
     --policy-document file://updated-trust-policy.json
```

#### **Issue 2: Pod ImagePullBackOff**

```
Error: Failed to pull image "docker.cloudsmith.io/.../flask-app:latest"

Root Causes:
1. imagePullSecret missing or incorrect
2. CloudSmith credentials expired
3. Image doesn't exist in registry

Solution:
1. Check imagePullSecret exists:
   kubectl get secret cloudsmith-regcred -n default

2. Verify secret data:
   kubectl get secret cloudsmith-regcred -n default -o yaml

3. Recreate secret with correct credentials:
   kubectl delete secret cloudsmith-regcred -n default
   
   kubectl create secret docker-registry cloudsmith-regcred \
     --namespace default \
     --docker-server=docker.cloudsmith.io \
     --docker-username=<username> \
     --docker-password=<api-key>

4. Verify ServiceAccount has imagePullSecret:
   kubectl get sa flask-app-sa -n default -o yaml

5. Test image pull manually:
   docker login docker.cloudsmith.io
   docker pull docker.cloudsmith.io/.../flask-app:latest
```

#### **Issue 3: ALB Not Provisioning**

```
Error: Ingress created but no ALB DNS hostname

Root Causes:
1. ALB Controller not running
2. Insufficient IAM permissions
3. Subnet tags missing
4. Security group issues

Solution:
1. Check ALB Controller status:
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

2. Check controller logs:
   kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

3. Verify IAM role for service account:
   kubectl get sa aws-load-balancer-controller -n kube-system -o yaml
   
   Should have annotation:
   eks.amazonaws.com/role-arn: arn:aws:iam::...:role/flask-eks-alb-controller-role

4. Check subnet tags (required for ALB):
   Public subnets must have:
   ├─ kubernetes.io/role/elb = 1
   └─ kubernetes.io/cluster/flask-eks = shared

5. Verify Ingress annotations:
   kubectl get ingress flask-alb -n default -o yaml

6. Check AWS Console:
   EC2 → Load Balancers → Look for ALB with tag:
   elbv2.k8s.aws/cluster = flask-eks
```

#### **Issue 4: Persistent Volume Not Mounting**

```
Error: Pod stuck in ContainerCreating, volume mount fails

Root Causes:
1. EBS CSI Driver not installed
2. PVC not bound to PV
3. Node doesn't have permission to attach EBS
4. AZ mismatch (pod in different AZ than volume)

Solution:
1. Check EBS CSI Driver:
   kubectl get pods -n kube-system -l app=ebs-csi-controller

2. Check PVC status:
   kubectl get pvc -n default
   
   Status should be: Bound
   If Pending, check events:
   kubectl describe pvc persistent-photos-pvc -n default

3. Verify StorageClass exists:
   kubectl get storageclass gp2

4. Check IAM role for EBS CSI:
   kubectl get sa ebs-csi-controller-sa -n kube-system -o yaml
   
   Should have annotation:
   eks.amazonaws.com/role-arn: arn:aws:iam::...:role/flask-eks-ebs-csi-driver-role

5. Check node IAM permissions:
   aws iam get-role --role-name <node-role-name>
   
   Should have policy: AmazonEBSCSIDriverPolicy

6. Verify pod and volume in same AZ:
   kubectl get pod <pod-name> -n default -o wide
   kubectl get pv -o wide
```

#### **Issue 5: Deployment Rollout Stuck**

```
Error: Rollout stuck, new pods not becoming ready

Root Causes:
1. Health check failing
2. Image pull error
3. Application crash on startup
4. Resource limits too low

Solution:
1. Check rollout status:
   kubectl rollout status deployment/flask-app -n default

2. Check pod status:
   kubectl get pods -n default -l app=flask-app
   
   Look for: CrashLoopBackOff, ImagePullBackOff, Error

3. Check pod events:
   kubectl describe pod <pod-name> -n default

4. Check application logs:
   kubectl logs <pod-name> -n default
   kubectl logs <pod-name> -n default --previous  # Previous container

5. Check health endpoint manually:
   kubectl port-forward <pod-name> 5000:5000 -n default
   curl http://localhost:5000/health

6. Rollback if needed:
   kubectl rollout undo deployment/flask-app -n default

7. Check resource usage:
   kubectl top pod <pod-name> -n default
   
   If near limits, increase in deployment.yaml:
   resources:
     limits:
       cpu: 1000m
       memory: 1Gi
```

#### **Issue 6: Database Connection Errors**

```
Error: SQLite database locked or not found

Root Causes:
1. Database PVC not mounted
2. Multiple pods accessing same SQLite file (not supported)
3. File permissions issue
4. Database file corrupted

Solution:
1. Check PVC mount:
   kubectl exec <pod-name> -n default -- ls -la /app/instance

2. Check database file:
   kubectl exec <pod-name> -n default -- ls -la /app/instance/photos.db

3. SQLite limitations:
   ⚠️  SQLite doesn't support concurrent writes from multiple pods
   
   Options:
   ├─ Use ReadWriteOnce PVC (only one pod can mount)
   ├─ Scale to 1 replica
   └─ Migrate to PostgreSQL/MySQL for multi-pod support

4. Fix permissions:
   kubectl exec <pod-name> -n default -- chmod 644 /app/instance/photos.db

5. Backup and recreate database:
   kubectl exec <pod-name> -n default -- cp /app/instance/photos.db /app/instance/photos.db.bak
   kubectl exec <pod-name> -n default -- python -c "from app import db; db.create_all()"
```

---

## ✅ Best Practices

### **Security Best Practices**

```
1. Authentication & Authorization
   ✅ Use OIDC instead of long-lived credentials
   ✅ Implement least privilege IAM policies
   ✅ Use IAM roles for service accounts (IRSA)
   ✅ Rotate credentials regularly
   ✅ Enable MFA for AWS console access

2. Container Security
   ✅ Run containers as non-root user
   ✅ Use minimal base images (alpine, slim)
   ✅ Scan images for vulnerabilities (Trivy)
   ✅ Don't include secrets in images
   ✅ Use read-only root filesystem where possible

3. Code Security
   ✅ Run SAST scans (Bandit)
   ✅ Scan dependencies (Safety)
   ✅ Keep dependencies updated
   ✅ Use environment variables for configuration
   ✅ Validate all user inputs

4. Network Security
   ✅ Use private subnets for worker nodes
   ✅ Implement network policies
   ✅ Use security groups to restrict traffic
   ✅ Enable VPC flow logs
   ✅ Use TLS for external traffic (HTTPS)

5. Secrets Management
   ✅ Use Kubernetes Secrets (not ConfigMaps)
   ✅ Consider AWS Secrets Manager for sensitive data
   ✅ Never commit secrets to Git
   ✅ Use .gitignore for sensitive files
   ✅ Rotate secrets regularly
```

### **Kubernetes Best Practices**

```
1. Resource Management
   ✅ Set resource requests and limits
   ✅ Use horizontal pod autoscaling
   ✅ Monitor resource usage
   ✅ Use node affinity/anti-affinity
   ✅ Implement pod disruption budgets

2. High Availability
   ✅ Run multiple replicas (min 2)
   ✅ Spread pods across AZs
   ✅ Use rolling updates
   ✅ Implement health checks
   ✅ Set appropriate grace periods

3. Configuration
   ✅ Use ConfigMaps for configuration
   ✅ Use Secrets for sensitive data
   ✅ Externalize configuration from code
   ✅ Use namespaces for isolation
   ✅ Label resources consistently

4. Monitoring & Logging
   ✅ Implement health check endpoints
   ✅ Use structured logging
   ✅ Centralize logs (CloudWatch)
   ✅ Set up alerts for critical issues
   ✅ Monitor resource usage

5. Deployment
   ✅ Use declarative configurations (YAML)
   ✅ Version control all manifests
   ✅ Test in staging before production
   ✅ Implement rollback procedures
   ✅ Use GitOps workflows
```

### **CI/CD Best Practices**

```
1. Pipeline Design
   ✅ Fail fast (security scans first)
   ✅ Keep pipelines fast (<10 min)
   ✅ Cache dependencies
   ✅ Run jobs in parallel where possible
   ✅ Generate artifacts and reports

2. Testing
   ✅ Run security scans on every commit
   ✅ Test Docker builds locally first
   ✅ Validate Kubernetes manifests
   ✅ Test health endpoints
   ✅ Implement smoke tests

3. Deployment
   ✅ Use rolling updates
   ✅ Implement health checks
   ✅ Wait for rollout completion
   ✅ Verify deployment success
   ✅ Have rollback procedures ready

4. Monitoring
   ✅ Track pipeline success rate
   ✅ Monitor deployment duration
   ✅ Alert on failures
   ✅ Generate deployment summaries
   ✅ Keep audit logs

5. Maintenance
   ✅ Keep actions/tools updated
   ✅ Review and update dependencies
   ✅ Clean up old artifacts
   ✅ Document pipeline changes
   ✅ Regular security audits
```

### **Infrastructure Best Practices**

```
1. Terraform
   ✅ Use remote state (S3)
   ✅ Enable state locking (DynamoDB)
   ✅ Use modules for reusability
   ✅ Version control all code
   ✅ Run terraform plan before apply

2. AWS EKS
   ✅ Use managed node groups
   ✅ Enable cluster logging
   ✅ Use latest Kubernetes version
   ✅ Implement backup strategy
   ✅ Monitor cluster health

3. Networking
   ✅ Use private subnets for nodes
   ✅ Implement proper CIDR planning
   ✅ Use NAT gateways for outbound traffic
   ✅ Tag subnets for ALB discovery
   ✅ Enable VPC flow logs

4. Cost Optimization
   ✅ Use spot instances where appropriate
   ✅ Right-size node instances
   ✅ Implement autoscaling
   ✅ Clean up unused resources
   ✅ Monitor costs regularly

5. Disaster Recovery
   ✅ Backup persistent volumes
   ✅ Document recovery procedures
   ✅ Test disaster recovery
   ✅ Use multiple AZs
   ✅ Keep infrastructure code in Git
```

---

## 📚 Additional Resources

### **Documentation**
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### **Tools**
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Trivy Documentation](https://trivy.dev/)
- [Bandit Documentation](https://bandit.readthedocs.io/)

### **AWS Services**
- [Amazon EKS](https://aws.amazon.com/eks/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Amazon EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [AWS IAM OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)

---

## 📞 Support & Contact

For issues, questions, or contributions:
- **GitHub Issues**: [Create an issue](https://github.com/yuvanreddy/flask-app-update/issues)
- **Email**: your-email@example.com
- **Documentation**: This file

---

## 📝 Changelog

### Version 1.0 (October 9, 2025)
- Initial documentation
- Complete project flow explanation
- Architecture diagrams
- Troubleshooting guide
- Best practices

---

**Document End**

*This documentation is maintained as part of the MyApp project.*  
*Last Updated: October 9, 2025*
