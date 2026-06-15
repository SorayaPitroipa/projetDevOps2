# CI/CD Quick Start Guide

## 🚀 5-Minute Setup

### 1. Configure AWS OIDC (One-time setup)

```bash
# Navigate to scripts folder
cd scripts

# Run setup script (replace YOUR_ORG with your GitHub org)
bash setup-aws-oidc.sh eu-west-1 YOUR_ORG

# Example:
# bash setup-aws-oidc.sh eu-west-1 my-github-org
```

**What this does:**
- Creates OIDC provider in AWS
- Creates IAM role for GitHub Actions
- Attaches ECR & ECS permissions

### 2. Configure GitHub Secrets

```bash
# From project root
bash scripts/setup-github-secrets.sh your-username/your-repo

# Follow the interactive prompts to add:
# - AWS Role ARN (from step 1)
# - Snyk token (optional, for SAST)
# - DockerHub credentials (optional)

# Example:
# bash scripts/setup-github-secrets.sh DanielGlorieux/projetDevOps2
```

### 3. Push to Main Branch

```bash
git add .
git commit -m "chore: enable enhanced CI/CD pipeline"
git push origin main
```

**What happens automatically:**
1. ✅ Security scans (secrets, dependencies, code)
2. ✅ Tests run (backend + frontend with coverage)
3. ✅ Docker images built
4. ✅ Images scanned for vulnerabilities
5. ✅ Images pushed to AWS ECR
6. ✅ Results visible in GitHub Actions

### 4. View Results

- **GitHub Actions**: Go to your repo > Actions tab
- **Code Scanning**: Security > Code scanning alerts
- **Coverage**: codecov.io (after first test run)

---

## 📋 Required Secrets Setup

| Secret | Purpose | Scope |
|--------|---------|-------|
| `AWS_ROLE_TO_ASSUME` | Deploy to ECR/ECS | **Required** for AWS |
| `SNYK_TOKEN` | SAST scanning | Optional |
| `DOCKERHUB_USERNAME` | Push to DockerHub | Optional |
| `DOCKERHUB_TOKEN` | Push to DockerHub | Optional |

---

## 🔄 Deployment to ECS

Once images are in ECR, deploy manually:

**Via GitHub CLI:**
```bash
gh workflow run deploy-ecs.yml -f services=both -f image_tag=latest
```

**Via GitHub UI:**
1. Go to Actions tab
2. Select "Deploy to ECS"
3. Click "Run workflow"
4. Choose services to deploy
5. Done! ✅

---

## 📊 Pipeline Stages

```
Push → Security → Tests → Build → Scan → Push ECR → Deploy (manual)
```

**Time:** ~5-10 minutes per run

---

## ✨ What's New (vs. Original)

| Feature | Before | After |
|---------|--------|-------|
| **Backend Tests** | Basic tests | Tests + Coverage reports |
| **Frontend Tests** | ❌ Not run | ✅ Run + Coverage |
| **Frontend Audit** | ❌ Not run | ✅ npm audit included |
| **SAST** | Basic | Snyk code analysis |
| **Container Scan** | Informational | SARIF reports in GitHub |
| **ECR Tags** | `latest` only | `latest` + timestamped |
| **Documentation** | ❌ Missing | ✅ Comprehensive guide |

---

## 🧪 Test Locally Before Pushing

```bash
# Backend
cd Backend
python -m pytest tests/ -v

# Frontend
cd Frontend
npm test

# Docker (optional)
docker build -t test-backend ./Backend
docker build -t test-frontend ./Frontend
```

---

## 🐛 Troubleshooting

**Q: "AWS_ROLE_TO_ASSUME not set"**
- Run: `bash scripts/setup-github-secrets.sh`

**Q: "Tests failing"**
- Run tests locally first
- Check GitHub Actions logs

**Q: "ECR push fails"**
- Ensure AWS role is set
- Check IAM permissions
- Run setup script again

**Q: "Container scanning times out"**
- Normal for large images (Trivy takes time)
- Currently non-blocking

---

## 📚 Full Documentation

See [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for:
- Detailed architecture
- All available configurations
- Advanced customization
- Monitoring & troubleshooting

---

## 🎯 Next Steps

1. ✅ Complete steps 1-4 above
2. 📊 Monitor first pipeline run
3. 🔍 Review GitHub Actions logs
4. 📝 Customize as needed (see CI_CD_GUIDE.md)
5. 🚀 Deploy to ECS manually

