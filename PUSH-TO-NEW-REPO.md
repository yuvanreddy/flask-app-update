# Push to New GitHub Repository - Step by Step Guide

**Date:** October 9, 2025  
**Project:** Flask Photo Gallery with EKS Infrastructure

---

## 🎯 Overview

This guide will help you:
1. Create a new GitHub repository
2. Initialize Git in your project
3. Push all code to the new repository
4. Configure GitHub Actions secrets

---

## 📋 Prerequisites

- GitHub account
- Git installed on your machine
- GitHub CLI (optional, for easier setup)

---

## 🚀 Method 1: Using GitHub Web Interface (Recommended)

### **Step 1: Create New Repository on GitHub**

1. **Go to GitHub:**
   ```
   https://github.com/new
   ```

2. **Configure repository:**
   ```
   Repository name: flask-eks-monitoring
   Description: Flask Photo Gallery with EKS, Terraform, and Prometheus/Grafana monitoring
   Visibility: ○ Public  ● Private (recommended)
   
   ⬜ Add a README file (we already have one)
   ⬜ Add .gitignore (we already have one)
   ⬜ Choose a license
   ```

3. **Click "Create repository"**

4. **Copy the repository URL:**
   ```
   https://github.com/YOUR_USERNAME/flask-eks-monitoring.git
   ```

### **Step 2: Initialize Git in Your Project**

Open PowerShell in your project directory:

```powershell
# Navigate to project directory
cd C:\Users\AREReddy\Downloads\CascadeProjects\MyApp

# Initialize Git (if not already initialized)
git init

# Check current status
git status
```

### **Step 3: Create .gitignore File**

Create `.gitignore` to exclude sensitive and unnecessary files:

```powershell
# Create .gitignore
@"
# Terraform
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfvars
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
instance/
.pytest_cache/
*.egg-info/
dist/
build/

# Flask
instance/
.webassets-cache

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Secrets
*.pem
*.key
secrets/
.env

# Kubernetes
kubeconfig
*.kubeconfig

# Logs
*.log
logs/

# Temporary files
*.tmp
*.bak
*.backup
"@ | Out-File -FilePath .gitignore -Encoding utf8
```

### **Step 4: Add All Files to Git**

```powershell
# Add all files
git add .

# Check what will be committed
git status

# Commit with message
git commit -m "Initial commit: Flask Photo Gallery with EKS, Terraform, and Monitoring"
```

### **Step 5: Connect to Remote Repository**

```powershell
# Add remote repository (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/flask-eks-monitoring.git

# Verify remote
git remote -v
```

### **Step 6: Push to GitHub**

```powershell
# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

**Enter your GitHub credentials when prompted.**

---

## 🔐 Method 2: Using GitHub CLI (Easier)

### **Step 1: Install GitHub CLI**

```powershell
# Install using winget
winget install --id GitHub.cli

# Or using Chocolatey
choco install gh
```

### **Step 2: Authenticate**

```powershell
# Login to GitHub
gh auth login

# Follow the prompts:
# - What account: GitHub.com
# - Protocol: HTTPS
# - Authenticate: Login with a web browser
```

### **Step 3: Create Repository and Push**

```powershell
# Navigate to project directory
cd C:\Users\AREReddy\Downloads\CascadeProjects\MyApp

# Initialize Git
git init

# Add .gitignore (same as Method 1)

# Add all files
git add .
git commit -m "Initial commit: Flask Photo Gallery with EKS, Terraform, and Monitoring"

# Create repository and push (all in one command!)
gh repo create flask-eks-monitoring --private --source=. --remote=origin --push

# Or for public repository
gh repo create flask-eks-monitoring --public --source=. --remote=origin --push
```

---

## 🔑 Step 7: Configure GitHub Secrets

After pushing, configure required secrets for GitHub Actions:

### **Required Secrets:**

1. **Go to repository settings:**
   ```
   https://github.com/YOUR_USERNAME/flask-eks-monitoring/settings/secrets/actions
   ```

2. **Click "New repository secret"**

3. **Add these secrets:**

#### **Secret 1: AWS_ROLE_TO_ASSUME**
```
Name: AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::816069153839:role/github-deployer-role
```

#### **Secret 2: CLOUDSMITH_USERNAME** (if using CloudSmith)
```
Name: CLOUDSMITH_USERNAME
Value: your-cloudsmith-username
```

#### **Secret 3: CLOUDSMITH_API_KEY** (if using CloudSmith)
```
Name: CLOUDSMITH_API_KEY
Value: your-cloudsmith-api-key
```

#### **Secret 4: GRAFANA_ADMIN_PASSWORD** (optional)
```
Name: GRAFANA_ADMIN_PASSWORD
Value: your-secure-grafana-password
```

---

## 📁 Repository Structure

After pushing, your repository will have:

```
flask-eks-monitoring/
├── .github/
│   └── workflows/
│       ├── build-deploy-app.yml          # Application deployment
│       ├── deploy-monitoring.yml         # Monitoring deployment
│       └── terraform-infrastructure.yml  # Infrastructure management
├── terraform-eks/
│   ├── *.tf files                        # Terraform configuration
│   ├── terraform.tfvars                  # Variables (gitignored)
│   └── GITHUB-ACTIONS-TERRAFORM.md       # Terraform workflow docs
├── monitoring/
│   ├── prometheus-values.yaml            # Prometheus config
│   ├── flask-app-alerts.yaml             # Custom alerts
│   ├── MONITORING-INTEGRATION-GUIDE.md   # Setup guide
│   ├── FLASK-APP-PROMQL-QUERIES.md       # PromQL queries
│   ├── GRAFANA-DASHBOARD-CREATION-GUIDE.md
│   ├── ALERTS-AND-NOTIFICATIONS-GUIDE.md
│   ├── GITHUB-ACTIONS-MONITORING.md      # Monitoring workflow docs
│   └── QUICK-REFERENCE.md                # Quick reference
├── k8s/
│   ├── deployment.yaml                   # Kubernetes manifests
│   ├── service.yaml
│   ├── ingress.yaml
│   └── pvc.yaml
├── app.py                                # Flask application
├── requirements.txt                      # Python dependencies
├── Dockerfile                            # Container image
├── README.md                             # Project documentation
├── PROJECT-FLOW-DOCUMENTATION.md         # Complete flow guide
├── ACTUAL-INFRASTRUCTURE-DIAGRAM.md      # Infrastructure diagram
├── DEPLOYMENT-VERIFICATION-REPORT.md     # Verification report
├── CLEANUP-GUIDE.md                      # Cleanup procedures
└── .gitignore                            # Git ignore rules
```

---

## ✅ Verification

After pushing, verify:

### **1. Check Repository on GitHub**
```
https://github.com/YOUR_USERNAME/flask-eks-monitoring
```

Verify all files are present.

### **2. Check GitHub Actions**
```
https://github.com/YOUR_USERNAME/flask-eks-monitoring/actions
```

You should see 3 workflows:
- Build and Deploy Application
- Deploy Monitoring Stack
- Terraform Infrastructure Management

### **3. Check Secrets**
```
Settings → Secrets and variables → Actions
```

Verify all required secrets are configured.

---

## 🎯 Next Steps After Pushing

### **Step 1: Update Repository-Specific Values**

Edit these files to match your new repository:

**File: `.github/workflows/build-deploy-app.yml`**
```yaml
# Update if repository name changed
# Line ~10: Update paths if needed
```

**File: `terraform-eks/terraform.tfvars`**
```hcl
# Update GitHub repository reference
github_repo = "YOUR_USERNAME/flask-eks-monitoring"
```

**File: `README.md`**
```markdown
# Update repository URLs
https://github.com/YOUR_USERNAME/flask-eks-monitoring
```

### **Step 2: Commit and Push Updates**

```powershell
git add .
git commit -m "Update repository-specific configurations"
git push origin main
```

### **Step 3: Test Workflows**

1. **Test Terraform workflow:**
   ```
   Actions → Terraform Infrastructure Management → Run workflow
   Action: plan
   ```

2. **Deploy infrastructure:**
   ```
   Actions → Terraform Infrastructure Management → Run workflow
   Action: apply
   Auto-approve: ✅
   ```

3. **Deploy monitoring:**
   ```
   Actions → Deploy Monitoring Stack → Run workflow
   Action: install
   ```

4. **Deploy application:**
   ```
   Actions → Build and Deploy Application → Run workflow
   ```

---

## 🔄 Updating the Repository

### **Make Changes:**
```powershell
# Edit files
# ...

# Check status
git status

# Add changes
git add .

# Commit
git commit -m "Description of changes"

# Push
git push origin main
```

### **Pull Latest Changes:**
```powershell
git pull origin main
```

---

## 🌿 Branch Strategy (Optional)

### **Create Development Branch:**
```powershell
# Create and switch to dev branch
git checkout -b development

# Make changes
# ...

# Push dev branch
git push -u origin development
```

### **Create Feature Branch:**
```powershell
# Create feature branch
git checkout -b feature/monitoring-improvements

# Make changes
# ...

# Push feature branch
git push -u origin feature/monitoring-improvements
```

### **Merge via Pull Request:**
1. Go to GitHub repository
2. Click "Pull requests" → "New pull request"
3. Select branches to merge
4. Create pull request
5. Review and merge

---

## 🔐 Security Best Practices

### **1. Never Commit Secrets**

Files to NEVER commit:
- `terraform.tfvars` (contains sensitive values)
- `*.pem` files (SSH keys)
- `.env` files (environment variables)
- `kubeconfig` files
- Any file with passwords or API keys

### **2. Use .gitignore**

Already configured in Step 3 above.

### **3. Review Before Pushing**

```powershell
# Always review what you're committing
git status
git diff

# Review staged changes
git diff --staged
```

### **4. Use Branch Protection**

In GitHub repository settings:
```
Settings → Branches → Add rule
Branch name pattern: main
✓ Require pull request reviews before merging
✓ Require status checks to pass
```

---

## 🆘 Troubleshooting

### **Issue 1: Authentication Failed**

**Solution:**
```powershell
# Use Personal Access Token instead of password
# Generate token: GitHub → Settings → Developer settings → Personal access tokens

# Or use GitHub CLI
gh auth login
```

### **Issue 2: Large Files**

**Error:** File size exceeds GitHub's 100 MB limit

**Solution:**
```powershell
# Use Git LFS for large files
git lfs install
git lfs track "*.zip"
git add .gitattributes
```

### **Issue 3: Merge Conflicts**

**Solution:**
```powershell
# Pull latest changes
git pull origin main

# Resolve conflicts in files
# Edit conflicted files manually

# Mark as resolved
git add .
git commit -m "Resolve merge conflicts"
git push origin main
```

### **Issue 4: Wrong Files Committed**

**Solution:**
```powershell
# Remove file from Git but keep locally
git rm --cached filename

# Update .gitignore
echo "filename" >> .gitignore

# Commit
git add .gitignore
git commit -m "Remove sensitive file from Git"
git push origin main
```

---

## 📚 Useful Git Commands

```powershell
# Check status
git status

# View commit history
git log --oneline

# View remote URL
git remote -v

# Change remote URL
git remote set-url origin https://github.com/NEW_USERNAME/NEW_REPO.git

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# View differences
git diff

# Create branch
git checkout -b branch-name

# Switch branch
git checkout branch-name

# Delete branch
git branch -d branch-name

# Push all branches
git push --all origin

# Clone repository
git clone https://github.com/USERNAME/REPO.git
```

---

## ✅ Checklist

**Before Pushing:**
- [ ] Created .gitignore file
- [ ] Reviewed files to commit (no secrets)
- [ ] Committed with descriptive message
- [ ] Created GitHub repository

**After Pushing:**
- [ ] Verified all files on GitHub
- [ ] Configured GitHub secrets
- [ ] Updated repository-specific values
- [ ] Tested workflows
- [ ] Set up branch protection (optional)

**Repository Setup:**
- [ ] README.md is clear and informative
- [ ] Documentation is complete
- [ ] Workflows are configured
- [ ] Secrets are set
- [ ] Repository is public/private as intended

---

## 🎉 Success!

Your code is now on GitHub! 🚀

**Repository URL:**
```
https://github.com/YOUR_USERNAME/flask-eks-monitoring
```

**Next Steps:**
1. Share repository with team
2. Set up branch protection
3. Run workflows to deploy infrastructure
4. Monitor with Grafana
5. Iterate and improve!

---

**Created:** October 9, 2025  
**Status:** Ready to push to GitHub
