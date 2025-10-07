# Quick Deploy Script
Write-Host "🚀 Deploying Flask Photo Gallery..." -ForegroundColor Cyan

# Configure kubectl
Write-Host "`n📡 Configuring kubectl..." -ForegroundColor Yellow
aws eks update-kubeconfig --name flask-eks --region us-east-1

# Verify cluster
Write-Host "`n✅ Checking cluster nodes..." -ForegroundColor Yellow
kubectl get nodes

# Build and push image
Write-Host "`n🐳 Building Docker image..." -ForegroundColor Yellow
docker build -t docker.cloudsmith.io/flask-sample-app/photouploadd-app/flask-devops-demo:latest .

Write-Host "`n📦 Pushing to Cloudsmith..." -ForegroundColor Yellow
docker push docker.cloudsmith.io/flask-sample-app/photouploadd-app/flask-devops-demo:latest

# Create secret (skip if already exists)
Write-Host "`n🔐 Creating Cloudsmith secret..." -ForegroundColor Yellow
kubectl create secret docker-registry cloudsmith-regcred `
  --namespace=default `
  --docker-server=docker.cloudsmith.io `
  --docker-username=$env:CLOUDSMITH_USERNAME `
  --docker-password=$env:CLOUDSMITH_API_KEY `
  --docker-email=your@email.com `
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy persistent storage
Write-Host "`n💾 Creating persistent storage..." -ForegroundColor Yellow
kubectl apply -f k8s/persistent-storage.yaml

# Deploy application
Write-Host "`n🚢 Deploying application..." -ForegroundColor Yellow
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for pod
Write-Host "`n⏳ Waiting for pod to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=flask-app -n default --timeout=300s

# Get ALB URL
Write-Host "`n⏳ Waiting for ALB (this takes 2-3 minutes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

$ALB_URL = kubectl get ingress flask-alb -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

if ($ALB_URL) {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Main App:      http://$ALB_URL/" -ForegroundColor Cyan
    Write-Host "🏥 Health Check:  http://$ALB_URL/health" -ForegroundColor Cyan
    Write-Host "📸 Upload Page:   http://$ALB_URL/upload" -ForegroundColor Cyan
    Write-Host ""
    
    # Open in browser
    Start-Process "http://$ALB_URL"
} else {
    Write-Host "⚠️ ALB URL not ready yet. Run this to check:" -ForegroundColor Yellow
    Write-Host "kubectl get ingress flask-alb -n default" -ForegroundColor Cyan
}