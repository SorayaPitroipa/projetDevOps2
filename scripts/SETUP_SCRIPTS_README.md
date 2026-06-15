# Setup Scripts for CI/CD Pipeline

This directory contains automation scripts to configure the CI/CD pipeline with GitHub Actions and AWS.

## 📋 Available Scripts

### 1. `setup-aws-oidc.sh` - Configure AWS IAM

**Purpose:** Creates AWS IAM resources for GitHub Actions OIDC authentication

**Prerequisites:**
- AWS CLI installed and configured
- Appropriate AWS IAM permissions
- GitHub organization name

**Usage:**
```bash
bash setup-aws-oidc.sh [AWS_REGION] <GITHUB_ORG>

# Examples:
bash setup-aws-oidc.sh eu-west-1 my-github-org
bash setup-aws-oidc.sh us-east-1 DanielGlorieux
```

**What it does:**
1. Creates OIDC provider in AWS (if not exists)
2. Creates IAM role `github-actions-ecr-ecs`
3. Attaches ECR & ECS permissions
4. Displays IAM role ARN for GitHub secrets

**Output:**
```
🔐 Setting up AWS IAM for GitHub OIDC
   Region: eu-west-1
   GitHub Org: my-github-org

✨ Configuration Complete!
📋 Configuration Summary:
   Role ARN: arn:aws:iam::123456789012:role/github-actions-ecr-ecs
   Role Name: github-actions-ecr-ecs
```

**Permissions Created:**
- ECR: Get auth, describe, create repos, push images
- ECS: Describe services, register tasks, update services
- IAM: Pass role for task execution

---

### 2. `setup-github-secrets.sh` - Configure GitHub Secrets

**Purpose:** Interactive configuration of GitHub repository secrets and variables

**Prerequisites:**
- GitHub CLI (`gh`) installed
- Authenticated with GitHub (`gh auth login`)
- Repository access rights

**Usage:**
```bash
bash setup-github-secrets.sh <OWNER/REPO>

# Examples:
bash setup-github-secrets.sh DanielGlorieux/projetDevOps2
bash setup-github-secrets.sh my-username/my-repo
```

**Interactive Menu:**
```
🔐 Setting up GitHub Secrets for CI/CD Pipeline

📋 Choose what to configure:
1️⃣  AWS (ECR + ECS Deployment)
2️⃣  Security Scanning (Snyk)
3️⃣  DockerHub (optional image registry)
4️⃣  All of the above
5️⃣  Just view current secrets
```

**Option 1 - AWS:**
- Prompts for AWS Role ARN
- Prompts for AWS Region
- Sets `AWS_ROLE_TO_ASSUME` secret
- Sets `AWS_REGION` variable

**Option 2 - Snyk:**
- Prompts for Snyk API token
- Sets `SNYK_TOKEN` secret
- Enables SAST scanning in pipeline

**Option 3 - DockerHub:**
- Prompts for DockerHub username
- Prompts for DockerHub token
- Sets `DOCKERHUB_USERNAME` secret
- Sets `DOCKERHUB_TOKEN` secret
- Enables DockerHub image push

**Option 4 - All:**
- Runs all three configurations

**Option 5 - View:**
- Shows current secrets and variables

---

## 🚀 Complete Setup Workflow

### Step 1: Setup AWS Infrastructure (5 minutes)

```bash
# From project root
cd scripts
bash setup-aws-oidc.sh eu-west-1 your-github-org

# 💾 Copy the Role ARN from output
# Example: arn:aws:iam::123456789012:role/github-actions-ecr-ecs
```

### Step 2: Configure GitHub Secrets (2 minutes)

```bash
bash setup-github-secrets.sh your-username/your-repo

# Follow the interactive prompts
# When asked for AWS Role ARN, paste the one from Step 1
```

### Step 3: Verify Configuration

```bash
# Check GitHub secrets are set
gh secret list --repo your-username/your-repo

# Check GitHub variables
gh variable list --repo your-username/your-repo
```

### Step 4: Test Pipeline

```bash
# Push changes to trigger CI/CD
git add .
git commit -m "chore: enable CI/CD pipeline"
git push origin main

# Monitor in GitHub Actions
# https://github.com/your-username/your-repo/actions
```

---

## 🔍 Troubleshooting

### AWS Setup Issues

**Error: "AWS CLI not found"**
```bash
# Install AWS CLI
# Windows (PowerShell)
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# macOS
brew install awscli

# Linux
sudo apt-get install awscli
```

**Error: "Unable to locate credentials"**
```bash
# Configure AWS credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="eu-west-1"
```

**Error: "UnauthorizedOperation: You are not authorized"**
- Ensure your AWS IAM user has permissions to:
  - Create IAM roles
  - Create OIDC providers
  - Attach IAM policies

### GitHub Setup Issues

**Error: "gh: command not found"**
```bash
# Install GitHub CLI
# Windows (PowerShell)
winget install github.cli

# macOS
brew install gh

# Linux
sudo apt-get install gh
```

**Error: "Not authenticated with GitHub"**
```bash
# Login to GitHub
gh auth login

# Follow the prompts to authenticate
```

**Error: "Repository not found"**
- Use format: `owner/repo` (not `owner-repo`)
- Ensure you have permissions to the repository
- Verify the repository name is correct

---

## 📊 What Gets Configured

### AWS Resources
```
OIDC Provider (shared)
└── IAM Role: github-actions-ecr-ecs
    ├── Policy: ECR permissions
    ├── Policy: ECS permissions
    └── Trust: GitHub token validation
```

### GitHub Secrets
```
Repository > Settings > Secrets and variables > Actions

Secrets:
├── AWS_ROLE_TO_ASSUME (if AWS selected)
├── SNYK_TOKEN (if Snyk selected)
├── DOCKERHUB_USERNAME (if DockerHub selected)
└── DOCKERHUB_TOKEN (if DockerHub selected)

Variables:
├── AWS_REGION (if AWS selected)
├── ECS_CLUSTER (optional, defaults to projet-cloud-cluster)
├── ECS_BACKEND_SERVICE (optional)
└── ECS_FRONTEND_SERVICE (optional)
```

---

## 🔐 Security Considerations

1. **No Hard-Coded Credentials**: OIDC uses temporary tokens, not long-lived credentials
2. **Least Privilege**: IAM role only has permissions needed for ECR/ECS
3. **Token Rotation**: OIDC tokens are short-lived and automatically rotated
4. **Audit Trail**: All AWS API calls are logged in CloudTrail
5. **Repository Isolation**: Secrets are only available in GitHub Actions

---

## 📚 Documentation References

- **CI_CD_GUIDE.md** - Detailed pipeline documentation
- **QUICK_START_CI_CD.md** - 5-minute setup summary
- **AWS_DEPLOYMENT_GUIDE.md** - Full AWS deployment guide
- **PIPELINE_VISUALIZATION.md** - Visual pipeline overview

---

## ✅ Verification Checklist

- [ ] AWS CLI installed and configured
- [ ] GitHub CLI installed and authenticated
- [ ] `setup-aws-oidc.sh` completed successfully
- [ ] `setup-github-secrets.sh` completed successfully
- [ ] GitHub secrets visible in repository settings
- [ ] First CI/CD pipeline run triggered and completed
- [ ] Images built and pushed to ECR
- [ ] Container scans visible in GitHub Security tab

---

## 🚨 Emergency Procedures

### Remove All Secrets (Clean Reset)

```bash
# List secrets
gh secret list --repo your-username/your-repo

# Remove all (one by one)
gh secret delete AWS_ROLE_TO_ASSUME --repo your-username/your-repo
gh secret delete SNYK_TOKEN --repo your-username/your-repo
gh secret delete DOCKERHUB_USERNAME --repo your-username/your-repo
gh secret delete DOCKERHUB_TOKEN --repo your-username/your-repo

# Re-run setup scripts
bash setup-github-secrets.sh your-username/your-repo
```

### Recreate AWS OIDC Role

```bash
# Delete old role
aws iam delete-role-policy \
  --role-name github-actions-ecr-ecs \
  --policy-name github-ecr-ecs-policy

aws iam delete-role --role-name github-actions-ecr-ecs

# Re-run setup
bash setup-aws-oidc.sh eu-west-1 your-github-org
```

---

## 💡 Tips

1. **Keep Region Consistent**: Use same AWS region throughout
2. **Save Role ARN**: Keep IAM role ARN handy for reference
3. **Test with PR**: Test pipeline changes with Pull Requests first
4. **Monitor Logs**: Check GitHub Actions logs for any issues
5. **Regular Reviews**: Periodically review and update secrets

---

**Last Updated**: June 14, 2026  
**Status**: ✅ Ready for use

