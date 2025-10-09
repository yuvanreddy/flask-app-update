# OIDC Role Assumption Fix

## Problem
Error: `Not authorized to perform sts:AssumeRoleWithWebIdentity`

## Root Cause
The IAM role trust policy had an incorrect repository identifier:
- **Incorrect**: `repo:flask-app-update:*`
- **Correct**: `repo:yuvanreddy/flask-app-update:*`

The repository owner (`yuvanreddy`) was missing from the trust policy condition.

## What Was Fixed
Updated the trust policy for role `flask-eks-github-deployer` to include the full repository path with owner.

### Command Used
```bash
aws iam update-assume-role-policy \
  --role-name flask-eks-github-deployer \
  --policy-document file://updated-trust-policy.json
```

## Verification
The trust policy now correctly matches:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::816069153839:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:yuvanreddy/flask-app-update:*"
        }
      }
    }
  ]
}
```

## GitHub Actions Configuration
The role ARN to use in GitHub Actions secrets:
```
AWS_ROLE_TO_ASSUME=arn:aws:iam::816069153839:role/flask-eks-github-deployer
```

## Terraform State
The Terraform configuration in `main.tf` is already correct and uses the proper format:
```hcl
"token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
```

Where `var.github_repo` is set to `"yuvanreddy/flask-app-update"` in `variables.tf`.

## Next Steps
1. ✅ Trust policy updated
2. ✅ Terraform configuration verified
3. 🔄 Test GitHub Actions workflow to confirm OIDC authentication works
4. 🔄 If Terraform manages this role, run `terraform plan` to sync state

## Important Notes
- The OIDC provider exists and is correctly configured
- The thumbprint is valid: `2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f`
- The client ID list includes: `sts.amazonaws.com`
- Both workflows (`build-deploy-app.yml` and `terraform-apply-destroy.yml`) use the same role

## Testing
To test the fix, trigger either workflow:
1. Push to main branch (triggers build-deploy-app.yml)
2. Manually run terraform-apply-destroy.yml workflow

The OIDC authentication should now succeed.
