# Security Documentation

This document explains the security model and practices used in this application.

## Container Security

### Binding to All Interfaces (0.0.0.0)

**Issue**: Bandit flags binding to `0.0.0.0` as a potential security risk (B104).

**Why This Is Safe in Our Context**:

The application binds to `0.0.0.0:5000` because it runs in Docker containers deployed to Kubernetes. This is not only safe but **required** for the following reasons:

1. **Container Isolation**
   - The application runs inside a Docker container
   - Docker provides network namespace isolation
   - `0.0.0.0` in the container context means "all interfaces within the container"
   - This does NOT expose the application to all interfaces on the host

2. **Kubernetes Network Security**
   - Kubernetes Network Policies control pod-to-pod communication
   - Service objects control external access
   - Only explicitly exposed services are accessible

3. **AWS Security Layers**
   - **Security Groups**: Control traffic at the EC2/node level
   - **Network ACLs**: Control traffic at the subnet level
   - **Load Balancer**: Acts as a security boundary
   - **WAF (optional)**: Can be added for additional protection

4. **Application-Level Security**
   - Gunicorn runs the application in production (not Flask dev server)
   - Debug mode is explicitly disabled (`debug=False`)
   - No sensitive data in environment variables is exposed

### Security Architecture

```
Internet
    ↓
[AWS Load Balancer] ← Security Groups
    ↓
[Kubernetes Service] ← Network Policies
    ↓
[Pod: 0.0.0.0:5000] ← Container Isolation
    ↓
[Gunicorn + Flask App]
```

### Why Not Use 127.0.0.1?

Binding to `127.0.0.1` (localhost) would make the application **only accessible from within the container**, which would:
- Break Docker networking
- Prevent Kubernetes services from routing traffic
- Make health checks fail
- Render the application unusable

## Docker Security Best Practices

We follow these Docker security best practices:

### 1. Non-Root User
```dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```

### 2. Read-Only Root Filesystem (where possible)
```yaml
securityContext:
  readOnlyRootFilesystem: false  # False because we need write access for logs
```

### 3. Drop Capabilities
```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

### 4. No Privilege Escalation
```yaml
securityContext:
  allowPrivilegeEscalation: false
```

### 5. Minimal Base Image
- Using `python:3.11-slim` (not full or alpine for compatibility)
- Only necessary packages installed

## Kubernetes Security

### Network Policies

Consider adding NetworkPolicies to restrict traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: flask-app-network-policy
  namespace: flask-app
spec:
  podSelector:
    matchLabels:
      app: flask-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
    ports:
    - protocol: TCP
      port: 5000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### Pod Security Standards

The deployment follows **Restricted** pod security standards:
- Runs as non-root user
- No privileged mode
- Drops all capabilities
- Read-only root filesystem (where applicable)

### Resource Limits

Resource limits prevent DoS attacks:
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Application Security

### 1. Dependencies

We scan dependencies for vulnerabilities:
- **Safety**: Checks Python dependencies against vulnerability database
- **Trivy**: Scans both filesystem and container images
- **Dependabot**: Automated dependency updates (configure in GitHub)

### 2. Code Scanning

Multiple security scanners in CI/CD:
- **Bandit**: Python security linter
- **Pylint**: Code quality and security
- **Trivy**: Container and filesystem scanning

### 3. Secrets Management

**Never commit secrets**:
- Use Kubernetes Secrets
- Use AWS Secrets Manager or Parameter Store
- Use environment variables for non-sensitive config

### 4. Input Validation

Always validate and sanitize user input:
```python
from flask import request
import bleach

@app.route('/api/data', methods=['POST'])
def post_data():
    data = request.get_json()
    # Validate data
    if not isinstance(data, dict):
        return jsonify({'error': 'Invalid input'}), 400
    # Sanitize if needed
    return jsonify({'data': data}), 201
```

### 5. CORS Configuration

Configure CORS properly for production:
```python
from flask_cors import CORS

# Allow only specific origins
CORS(app, origins=['https://yourdomain.com'])
```

## AWS Security

### IAM Roles

Use least-privilege IAM roles:
- **EKS Cluster Role**: Minimum permissions for cluster management
- **Node Group Role**: Access to ECR, EC2, CloudWatch only
- **IRSA (IAM Roles for Service Accounts)**: Fine-grained permissions per pod

### Security Groups

Restrict traffic at multiple levels:
```hcl
# Allow only necessary ports
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Public traffic
}

ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # Public traffic
}
```

### Encryption

- **EBS volumes**: Encrypted by default in Terraform config
- **Secrets**: Encrypted at rest in Kubernetes
- **In transit**: Use TLS/HTTPS for all external communication

## CI/CD Security

### GitHub Actions Security

1. **Secrets Management**
   - Never log secrets
   - Use GitHub Secrets for sensitive data
   - Rotate credentials regularly

2. **Dependency Pinning**
   - Pin action versions: `uses: actions/checkout@v4`
   - Review dependency updates

3. **Least Privilege**
   - Minimize AWS permissions
   - Use short-lived credentials where possible

### Container Registry

- **Cloudsmith**: Private registry for Docker images
- **Vulnerability scanning**: Automated on push
- **Image signing**: Consider implementing Cosign

## Monitoring and Incident Response

### Logging

- **Application logs**: Structured JSON logging
- **Access logs**: Via Ingress/Load Balancer
- **Audit logs**: EKS control plane logs to CloudWatch

### Alerting

Set up alerts for:
- Failed authentication attempts
- Unusual traffic patterns
- Resource exhaustion
- Security scan failures

### Incident Response

1. **Detection**: Monitor security scan results and CloudWatch
2. **Containment**: Scale down or delete affected pods
3. **Investigation**: Check logs and audit trails
4. **Recovery**: Deploy patched version
5. **Post-mortem**: Document and improve

## Security Checklist

- [x] Non-root container user
- [x] Security context configured
- [x] Resource limits set
- [x] Health checks implemented
- [x] Secrets in Kubernetes Secrets/AWS
- [x] Dependencies scanned
- [x] Code scanned (Bandit, Pylint)
- [x] Container scanned (Trivy)
- [x] Network policies (optional, implement if needed)
- [ ] TLS/HTTPS configured (implement with Ingress)
- [ ] WAF configured (optional for production)
- [ ] Rate limiting (implement as needed)
- [ ] Authentication/Authorization (implement based on requirements)

## Security Updates

### Process

1. **Monitor**: Watch for security advisories
2. **Assess**: Evaluate impact on application
3. **Test**: Test updates in non-production environment
4. **Deploy**: Roll out with monitoring
5. **Verify**: Confirm fix without breaking changes

### Update Cadence

- **Dependencies**: Monthly or when critical vulnerabilities found
- **Base images**: Monthly
- **Kubernetes**: Quarterly or per AWS recommendations
- **Security policies**: As needed

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public GitHub issue
2. Email: security@yourdomain.com (update with actual contact)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/security-best-practices/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

## Compliance

Document any compliance requirements:
- GDPR
- HIPAA
- SOC 2
- PCI DSS

And how this application meets them.

---

**Last Updated**: 2025-09-30
**Next Review**: 2025-12-30