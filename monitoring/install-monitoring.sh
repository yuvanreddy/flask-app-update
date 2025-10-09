#!/bin/bash
# Install Prometheus + Grafana Monitoring Stack
# Usage: ./install-monitoring.sh

set -e

echo "=========================================="
echo "Installing Prometheus + Grafana Stack"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: helm is not installed${NC}"
    exit 1
fi

# Check cluster connection
echo -e "${YELLOW}Checking cluster connection...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to cluster${NC}"

# Add Prometheus Helm repo
echo -e "${YELLOW}Adding Prometheus Helm repository...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
echo -e "${GREEN}✓ Helm repository added${NC}"

# Create monitoring namespace
echo -e "${YELLOW}Creating monitoring namespace...${NC}"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"

# Install Prometheus stack
echo -e "${YELLOW}Installing Prometheus stack (this may take 5-10 minutes)...${NC}"
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --version 55.0.0 \
  --wait \
  --timeout 15m

echo -e "${GREEN}✓ Prometheus stack installed${NC}"

# Wait for pods to be ready
echo -e "${YELLOW}Waiting for all pods to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  --all \
  --namespace=monitoring \
  --timeout=600s

echo -e "${GREEN}✓ All pods are ready${NC}"

# Apply custom alerts
echo -e "${YELLOW}Applying Flask app custom alerts...${NC}"
kubectl apply -f flask-app-alerts.yaml
echo -e "${GREEN}✓ Custom alerts applied${NC}"

# Get Grafana service details
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""

# Get Grafana LoadBalancer URL
GRAFANA_LB=$(kubectl get svc -n monitoring prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

if [ "$GRAFANA_LB" != "pending" ]; then
    echo -e "${GREEN}Grafana is accessible at:${NC}"
    echo "  URL: http://$GRAFANA_LB"
else
    echo -e "${YELLOW}Grafana LoadBalancer is being provisioned...${NC}"
    echo "Run this command to check status:"
    echo "  kubectl get svc -n monitoring prometheus-stack-grafana"
fi

echo ""
echo -e "${GREEN}Grafana Credentials:${NC}"
echo "  Username: admin"
echo "  Password: (check prometheus-values.yaml)"
echo ""

# Port forward instructions
echo "=========================================="
echo "Quick Access (Port Forward):"
echo "=========================================="
echo ""
echo "Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80"
echo "  Then open: http://localhost:3000"
echo ""
echo "Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "Alertmanager:"
echo "  kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093"
echo "  Then open: http://localhost:9093"
echo ""

# Show pods
echo "=========================================="
echo "Monitoring Pods:"
echo "=========================================="
kubectl get pods -n monitoring

echo ""
echo -e "${GREEN}Installation successful!${NC}"
echo ""
echo "Next steps:"
echo "1. Access Grafana and login with admin credentials"
echo "2. Explore pre-installed dashboards"
echo "3. Configure alerting (email/Slack) in prometheus-values.yaml"
echo "4. Optional: Create Ingress for external access"
echo ""
