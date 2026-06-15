# CI/CD Pipeline Guide - Finance AWS Project

## Overview

This document describes the enhanced CI/CD pipeline for the Finance AWS project, including testing, security scanning, Docker image builds, and deployment to AWS ECS.

## Pipeline Architecture

```
┌─────────────────┐
│   Git Push      │
│   (main branch) │
└────────┬────────┘
         │
    ┌────▼──────────────────────┐
    │  SECURITY SCANS (parallel)│
    │  • Trufflehog (secrets)   │
    │  • pip-audit (Python)     │
    │  • Snyk (SAST)            │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────────────┐
    │  TESTING (parallel)        │
    │  • Backend (pytest)        │
    │  • Frontend (npm test)     │
    │  • Code Coverage (Codecov) │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────────────┐
    │  BUILD (parallel)          │
    │  • Frontend build          │
    │  • Backend + Frontend      │
    │    Docker images           │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────────────┐
    │  IMAGE SCANNING (Trivy)    │
    │  • Container vuln checks   │
    │  • SARIF reports           │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────────────┐
    │  PUSH IMAGES               │
    │  • DockerHub (optional)    │
    │  • AWS ECR (with OIDC)     │
    └────┬──────────────────────┘
         │
    ┌────▼──────────────────────┐
    │  DEPLOY (manual trigger)   │
    │  • Update ECS services     │
    │  • Rolling deployment      │
    └────────────────────────────┘
```

## Required GitHub Secrets

Configure these secrets in your GitHub repository under **Settings > Secrets and variables > Actions**:

### Optional Secrets

#### DockerHub (for pushing to DockerHub)
```
DOCKERHUB_USERNAME      # Your DockerHub username
DOCKERHUB_TOKEN         # DockerHub Personal Access Token
```

#### AWS (for ECR + ECS deployment)
```
AWS_ROLE_TO_ASSUME      # IAM role ARN for OIDC (e.g., arn:aws:iam::123456789:role/github-actions-role)
```

#### Snyk (for SAST scanning)
```
SNYK_TOKEN             # Snyk API token for code scanning
```

### Optional Variables

```
AWS_REGION             # AWS region (default: eu-west-1)
ECS_CLUSTER            # ECS cluster name (default: projet-cloud-cluster)
ECS_BACKEND_SERVICE    # Backend service name (default: projet-cloud-backend-service)
ECS_FRONTEND_SERVICE   # Frontend service name (default: projet-cloud-frontend-service)
```

## Job Details

### 1. Security Scans

**Triggers:** On every push to main and PR

**Steps:**
- **Trufflehog**: Scans for hardcoded secrets (API keys, tokens, etc.)
- **pip-audit**: Audits Python dependencies for known vulnerabilities
- **Snyk Code**: Static Application Security Testing (SAST) for code analysis

**Artifacts:** 
- Security scan logs in GitHub Actions output
- Snyk results shown in PR comments (if configured)

### 2. Testing

**Triggers:** After security scans pass

#### Backend Tests
```bash
# Located: Backend/
python -m pytest --cov=app --cov-report=xml tests/
```
- Runs all test files in `tests/`
- Generates code coverage report (XML format)
- Uploads to Codecov.io for tracking

#### Frontend Tests
```bash
# Located: Frontend/
npm audit --audit-level=moderate
npm run test -- --watch=false --code-coverage
```
- Audits npm dependencies
- Runs Angular test suite
- Generates coverage report

### 3. Build

**Triggers:** After tests pass

#### Frontend Build
```bash
npm install --legacy-peer-deps
npm run build  # Outputs to dist/
```

#### Docker Images Build
- **Backend**: Python FastAPI application
- **Frontend**: Angular app (nginx)
- Built using multi-stage Docker files for optimization

### 4. Image Scanning

**Triggers:** After Docker build

**Trivy Scanning:**
- Scans for CRITICAL vulnerabilities in container images
- Generates SARIF reports (GitHub Code Scanning format)
- Results visible in GitHub Security tab
- Non-blocking (informational only currently)

### 5. Push to Registries

**Triggers:** On push to main branch only

#### DockerHub (Optional)
- Pushes images: `username/projet-cloud-backend:latest`
- Requires: `DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN` secrets

#### AWS ECR
- Creates repositories if they don't exist
- Uses OIDC authentication (no long-lived credentials)
- Tags images with:
  - `latest` - always the latest main branch build
  - `YYYYMMDD-HHMMSS-<SHORT_SHA>` - timestamped version for rollback

Example ECR image tags:
```
123456789.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-backend:latest
123456789.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-backend:20260614-143022-a1b2c3d
```

### 6. Deploy to ECS (Manual Trigger)

**Workflow:** `deploy-ecs.yml`

**Trigger:** Manual via GitHub Actions UI or API

**Options:**
- Choose image tag to deploy
- Deploy backend, frontend, or both

**Process:**
1. Fetch current ECS task definition
2. Update container image references
3. Inject environment variables from GitHub secrets/variables
4. Register new task definition revision
5. Update ECS service
6. Wait for service stability

---

## Setup Instructions

### Prerequisites

1. **GitHub Repository**
   - Fork or clone the repository
   - Enable GitHub Actions
   - Configure repository secrets

2. **AWS Account** (for production deployment)
   - Create IAM role for GitHub OIDC
   - Create ECS cluster, services, task definitions
   - Create ECR repositories

3. **Optional Services**
   - Codecov account (for coverage tracking)
   - Snyk account (for SAST scanning)
   - DockerHub account (to push images)

### 1. Configure GitHub OIDC for AWS

Create an IAM role that GitHub Actions can assume:

```bash
# 1. Create OIDC provider in AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create IAM role with trust relationship
# See: infra/aws/AUTOMATION.md for detailed instructions
```

### 2. Create GitHub Secrets

```bash
# Set AWS role ARN (use AWS CLI or GitHub UI)
gh secret set AWS_ROLE_TO_ASSUME --body "arn:aws:iam::123456789:role/github-actions-role"

# Set Snyk token (optional)
gh secret set SNYK_TOKEN --body "your-snyk-token"

# Set DockerHub credentials (optional)
gh secret set DOCKERHUB_USERNAME --body "your-username"
gh secret set DOCKERHUB_TOKEN --body "your-dockerhub-token"
```

### 3. Configure ECS Resources

Update GitHub variables with your ECS resources:

```bash
gh variable set AWS_REGION --body "eu-west-1"
gh variable set ECS_CLUSTER --body "your-cluster-name"
gh variable set ECS_BACKEND_SERVICE --body "your-backend-service"
gh variable set ECS_FRONTEND_SERVICE --body "your-frontend-service"
```

---

## Running the Pipeline

### Automatic Triggers

The pipeline runs automatically when:
- Code is pushed to `main` branch
- Pull request is created against `main` branch

### Manual Deployment

Deploy to ECS manually:

```bash
# Option 1: Via GitHub CLI
gh workflow run deploy-ecs.yml \
  -f image_tag=latest \
  -f services=both

# Option 2: Via GitHub UI
# Go to Actions > Deploy to ECS > Run workflow
```

---

## Monitoring & Troubleshooting

### View Workflow Results

1. **GitHub Actions**: Go to repository > Actions tab
2. **Code Scanning**: Go to Security > Code scanning alerts
3. **Codecov**: Check coverage reports at codecov.io

### Common Issues

#### ❌ "AWS_ROLE_TO_ASSUME not found"
- **Solution**: Add `AWS_ROLE_TO_ASSUME` secret in GitHub Settings

#### ❌ "ECR repositories not found"
- **Solution**: Workflow auto-creates them on first run, or create manually:
  ```bash
  aws ecr create-repository --repository-name projet-cloud-backend
  aws ecr create-repository --repository-name projet-cloud-frontend
  ```

#### ❌ "Tests failing"
- Check test logs in GitHub Actions
- Run locally: `python -m pytest Backend/tests/` or `npm test`

#### ❌ "Trivy scanning times out"
- Trivy scans large images can take time
- Currently non-blocking (informational only)

#### ❌ "OIDC authentication fails"
- Verify IAM role trust policy allows GitHub Actions
- Check region configuration matches

---

## Best Practices

### For Development

1. **Before pushing to main:**
   ```bash
   # Run tests locally
   cd Backend && python -m pytest tests/
   cd Frontend && npm test
   
   # Check code quality
   python -m pylint app/
   ```

2. **Use feature branches**
   - Create PR before merging to main
   - Let CI/CD validate changes

3. **Keep dependencies updated**
   - Regularly update `requirements.txt` and `package.json`
   - Review security advisories

### For Deployment

1. **Tag releases** in Git for production deployments
2. **Monitor ECS** after deployment for issues
3. **Keep rollback plan** ready (easy with timestamped ECR tags)
4. **Review scan reports** before deploying CRITICAL images

---

## Advanced Configuration

### Adding SonarQube for Code Quality

Add to `.github/workflows/ci-cd.yml`:

```yaml
- name: SonarQube scan
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Slack Notifications on Failure

Add to workflow:

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

### Automated Security Patch Detection

```yaml
- name: Dependabot alerts check
  run: gh api repos/${{ github.repository }}/vulnerability-alerts
```

---

## Useful Links

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS OIDC Provider Setup](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Trivy Scanner](https://github.com/aquasecurity/trivy)
- [Snyk Security](https://snyk.io)
- [Codecov Integration](https://codecov.io)

---

## Support

For issues or improvements to the CI/CD pipeline:
1. Check GitHub Actions logs
2. Review this guide
3. Consult AWS/Snyk documentation
4. Open an issue in the repository

