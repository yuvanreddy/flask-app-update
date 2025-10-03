# AWS Load Balancer Controller Integration

## Overview

The AWS Load Balancer Controller has been integrated into the Terraform EKS infrastructure. This controller manages AWS Elastic Load Balancers for Kubernetes clusters, automatically provisioning Application Load Balancers (ALB) and Network Load Balancers (NLB) based on Kubernetes Ingress and Service resources.

## What Was Added

### Terraform Resources

**New File: `terraform-eks/modules/eks/alb-controller.tf`**
- IAM policy for AWS Load Balancer Controller
- IAM role using IRSA (IAM Roles for Service Accounts)
- Policy attachment

**Updated Files:**
- `terraform-eks/modules/eks/variables.tf` - Added `enable_alb_controller` variable
- `terraform-eks/modules/eks/outputs.tf` - Added ALB controller role ARN output
- `terraform-eks/variables.tf` - Added `enable_alb_controller` variable
- `terraform-eks/main.tf` - Passed `enable_alb_controller` to EKS module

### Kubernetes Resources

**New File: `terraform-eks/kubernetes/aws-load-balancer-controller.yaml`**
- ServiceAccount with IRSA annotation
- ClusterRole and ClusterRoleBinding
- Deployment (2 replicas)
- Service for webhooks
- IngressClass definition

### Deployment Scripts

**New Files:**
- `terraform-eks/scripts/deploy-alb-controller.sh` - Bash deployment script
- `terraform-eks/scripts/deploy-alb-controller.ps1` - PowerShell deployment script

## How It Works

1. **Terraform creates IAM resources** during cluster deployment
2. **IAM role uses IRSA** to grant permissions without AWS credentials
3. **After cluster creation**, run deployment script to install controller
4. **Controller watches** for Kubernetes Ingress and Service resources
5. **Automatically provisions** AWS Load Balancers when needed

## Deployment Process

### Prerequisites

- EKS cluster must be created and running
- kubectl configured to access the cluster
- Terraform outputs available

### Deploy Controller (After EKS Creation)

**On Windows (PowerShell):**
```powershell
cd terraform-eks\scripts
.\deploy-alb-controller.ps1
```

**On Linux/Mac (Bash):**
```bash
cd terraform-eks/scripts
chmod +x deploy-alb-controller.sh
./deploy-alb-controller.sh
```

### Verify Installation

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

Expected output: 2 pods running

## Using the Load Balancer Controller

### Example: Flask App with Ingress

Create `flask-ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /health
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: flask-app-service
                port:
                  number: 80
```

Apply:
```bash
kubectl apply -f flask-ingress.yaml
```

The controller will automatically:
1. Create an Application Load Balancer
2. Configure target groups
3. Set up health checks
4. Update Ingress status with ALB DNS name

### Get Load Balancer URL

```bash
kubectl get ingress flask-app-ingress
```

Look for the ADDRESS column - this is your ALB DNS name.

## Features Enabled

- **Automatic ALB provisioning** from Kubernetes Ingress
- **Target group management** 
- **Health check configuration**
- **SSL/TLS termination** (when configured)
- **Host and path-based routing**
- **Integration with AWS WAF** (optional)
- **Integration with AWS Shield** (optional)

## Cost Considerations

### Additional Costs with ALB Controller

**Application Load Balancer:**
- $0.0225 per hour per ALB (~$16/month)
- $0.008 per LCU-hour (Load Balancer Capacity Unit)

**Network Load Balancer (if used):**
- $0.0225 per hour per NLB (~$16/month)
- $0.006 per NLCU-hour

**Example:**
- 1 ALB for Flask app: ~$20-30/month
- Total EKS + ALB cost: ~$200-210/month

## Configuration Options

### Common Ingress Annotations

```yaml
metadata:
  annotations:
    # Scheme
    alb.ingress.kubernetes.io/scheme: internet-facing  # or internal
    
    # Target type
    alb.ingress.kubernetes.io/target-type: ip  # or instance
    
    # SSL
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
    
    # Health checks
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    
    # Load balancer attributes
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=60
```

### Service Type LoadBalancer (Alternative)

If you use Service type LoadBalancer instead of Ingress:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-app-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  selector:
    app: flask-app
  ports:
    - port: 80
      targetPort: 5000
```

This creates a Network Load Balancer instead of ALB.

## Troubleshooting

### Controller Not Installing

**Issue:** Pods not starting

**Check:**
```bash
kubectl describe pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

**Common causes:**
- IAM role ARN incorrect
- OIDC provider not configured
- CRDs not installed

### Load Balancer Not Created

**Issue:** Ingress created but no ALB appears

**Check:**
```bash
kubectl describe ingress flask-app-ingress
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Common causes:**
- Incorrect IngressClass
- Missing required annotations
- Subnet tags missing
- IAM permissions insufficient

### Check IAM Role

```bash
# Get IAM role from Terraform
terraform output alb_controller_role_arn

# Verify role exists in AWS
aws iam get-role --role-name flask-eks-cluster-alb-controller-role
```

## Monitoring

### View Controller Logs

```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f
```

### Check Controller Events

```bash
kubectl get events -n kube-system --sort-by='.lastTimestamp' | grep aws-load-balancer-controller
```

### View Managed Load Balancers

```bash
aws elbv2 describe-load-balancers --region us-east-1
```

## Uninstalling

To remove the AWS Load Balancer Controller:

```bash
# Delete the controller
kubectl delete -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# Manually delete any remaining ALBs/NLBs from AWS Console or CLI
aws elbv2 describe-load-balancers --region us-east-1
aws elbv2 delete-load-balancer --load-balancer-arn <arn>
```

## Additional Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Ingress Annotations Reference](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/guide/ingress/annotations/)
- [ALB Ingress Best Practices](https://aws.amazon.com/blogs/containers/best-practices-for-aws-load-balancer-controller/)

## Next Steps

After deploying the controller:

1. Deploy your Flask application to the cluster
2. Create an Ingress resource to expose it
3. Access your application via the ALB DNS name
4. (Optional) Configure custom domain with Route 53
5. (Optional) Add SSL certificate from ACM