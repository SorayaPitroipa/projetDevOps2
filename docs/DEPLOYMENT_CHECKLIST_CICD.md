# CI/CD Deployment Checklist

**Project:** Finance AWS (projetDevOps2)  
**Date:** _______________  
**Completed By:** _______________

---

## Phase 1: Pre-Deployment (AWS Infrastructure) ⚙️

### AWS Account Setup
- [ ] AWS account is active and accessible
- [ ] AWS CLI is installed (`aws --version`)
- [ ] AWS CLI is configured (`aws configure` done)
- [ ] Have appropriate IAM permissions:
  - [ ] Create IAM roles
  - [ ] Create OIDC providers
  - [ ] Create ECR repositories
  - [ ] Access to ECS services

### AWS OIDC Configuration
- [ ] Run AWS OIDC setup script:
  ```bash
  bash scripts/setup-aws-oidc.sh eu-west-1 your-github-org
  ```
- [ ] Script completed successfully
- [ ] Copy IAM Role ARN from output:
  ```
  Role ARN: _________________________________
  ```
- [ ] Verify role was created in AWS:
  - [ ] Log into AWS Console
  - [ ] Go to IAM > Roles
  - [ ] Search for `github-actions-ecr-ecs`
  - [ ] Verify policies attached

---

## Phase 2: GitHub Configuration 🔐

### GitHub Repository Setup
- [ ] Repository is forked/cloned
- [ ] You have admin/write access
- [ ] GitHub CLI is installed (`gh --version`)
- [ ] GitHub CLI is authenticated (`gh auth status`)
- [ ] Repository name noted:
  ```
  Repository: _________________________________
  Format: owner/repo-name
  ```

### GitHub Secrets Configuration
- [ ] Run GitHub secrets setup script:
  ```bash
  bash scripts/setup-github-secrets.sh owner/repo
  ```
- [ ] When prompted, select "All of the above" (option 4)
- [ ] When prompted for AWS Role ARN, paste the one from Phase 1
- [ ] When prompted for optional items:
  - [ ] Enter Snyk token (if you have one, otherwise leave empty)
  - [ ] Enter DockerHub credentials (if you have them, otherwise skip)

### Verify Secrets Were Set
- [ ] GitHub CLI shows secrets:
  ```bash
  gh secret list --repo owner/repo
  ```
- [ ] Expected secrets visible:
  - [ ] `AWS_ROLE_TO_ASSUME`
  - [ ] `SNYK_TOKEN` (if configured)
  - [ ] `DOCKERHUB_USERNAME` (if configured)
  - [ ] `DOCKERHUB_TOKEN` (if configured)

### Verify Variables Were Set
- [ ] GitHub CLI shows variables:
  ```bash
  gh variable list --repo owner/repo
  ```
- [ ] Expected variables visible:
  - [ ] `AWS_REGION`
  - [ ] Optional: `ECS_CLUSTER`, `ECS_BACKEND_SERVICE`, `ECS_FRONTEND_SERVICE`

---

## Phase 3: Local Testing 🧪

### Backend Tests
- [ ] Navigate to Backend directory:
  ```bash
  cd Backend
  ```
- [ ] Install dependencies:
  ```bash
  python -m pip install -r requirements.txt
  ```
- [ ] Run tests locally:
  ```bash
  python -m pytest tests/ -v
  ```
- [ ] All tests pass:
  - [ ] No failures
  - [ ] No errors
  - [ ] All assertions succeed

### Frontend Tests
- [ ] Navigate to Frontend directory:
  ```bash
  cd Frontend
  ```
- [ ] Install dependencies:
  ```bash
  npm install
  ```
- [ ] Check for npm vulnerabilities:
  ```bash
  npm audit
  ```
- [ ] Note any critical vulnerabilities (if any):
  ```
  Vulnerabilities found: _____________________
  ```

### Docker Build (Optional but Recommended)
- [ ] Build backend image:
  ```bash
  docker build -t test-backend ./Backend
  ```
- [ ] Build frontend image:
  ```bash
  docker build -t test-frontend ./Frontend
  ```
- [ ] Both images build successfully:
  - [ ] No build errors
  - [ ] Both images appear in `docker images`

---

## Phase 4: First Pipeline Run ✅

### Push Changes to Trigger Pipeline
- [ ] Commit any pending changes:
  ```bash
  git add .
  git commit -m "chore: enable enhanced CI/CD pipeline"
  ```
- [ ] Push to main branch:
  ```bash
  git push origin main
  ```
- [ ] Changes successfully pushed

### Monitor Pipeline in GitHub Actions
- [ ] Go to Actions tab: `https://github.com/owner/repo/actions`
- [ ] Pipeline workflow started:
  - [ ] Status shows "Running" or "Completed"
  - [ ] "CI/CD" workflow is visible
- [ ] Watch for stage completions (in order):
  1. [ ] Security scans (2-3 min)
  2. [ ] Backend tests (2-3 min)
  3. [ ] Frontend tests (2-3 min)
  4. [ ] Build frontend (2-3 min)
  5. [ ] Build Docker images (4-5 min)
  6. [ ] Scan images with Trivy (3-4 min)
  7. [ ] Push to ECR (2 min)

### Verify Pipeline Success
- [ ] Pipeline shows ✅ (all green):
  - [ ] No red X marks
  - [ ] All jobs completed
  - [ ] No warnings or errors
- [ ] Check individual jobs for any issues:
  - [ ] Click each job to view logs if needed

### Review Security Scan Results
- [ ] Go to GitHub Security tab (if available)
- [ ] Check for any critical vulnerabilities:
  - [ ] Container scanning results
  - [ ] Code scanning results
- [ ] Note any issues:
  ```
  Security Issues Found: _____________________
  Action Required: _________________________
  ```

---

## Phase 5: AWS ECR Verification ☁️

### Verify Images in ECR
- [ ] Log into AWS Console
- [ ] Go to ECR > Repositories
- [ ] Verify two repositories exist:
  - [ ] `projet-cloud-backend`
  - [ ] `projet-cloud-frontend`
- [ ] Verify images were pushed:
  - [ ] Backend repository has images
  - [ ] Frontend repository has images
- [ ] Verify image tags:
  - [ ] `latest` tag present
  - [ ] Timestamped tag present (YYYYMMDD-HHMMSS-SHA)

### Check Image Details
- [ ] Click on backend image, verify:
  - [ ] Image size reasonable (< 1 GB)
  - [ ] Push date matches pipeline run
  - [ ] URI format: `123456789.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-backend:latest`

---

## Phase 6: Documentation Review 📚

### Confirm Documentation
- [ ] CI_CD_GUIDE.md exists in docs/
- [ ] QUICK_START_CI_CD.md exists in docs/
- [ ] PIPELINE_VISUALIZATION.md exists in docs/
- [ ] CICD_ENHANCEMENT_SUMMARY.md exists in docs/
- [ ] Setup scripts are in scripts/:
  - [ ] setup-aws-oidc.sh
  - [ ] setup-github-secrets.sh
- [ ] SETUP_SCRIPTS_README.md exists in scripts/

### Share Documentation
- [ ] Documentation is accessible to team
- [ ] Team members know where to find setup guides
- [ ] Links are properly configured
- [ ] Documentation is up-to-date

---

## Phase 7: Deployment to ECS (Manual) 🚀

### Prerequisites for ECS Deployment
- [ ] ECS cluster exists and is active
- [ ] Task definitions are registered
- [ ] Services are configured
- [ ] ALB/Target Groups are set up
- [ ] Security groups allow traffic
- [ ] Database is accessible from ECS

### Trigger Manual Deployment
- [ ] Go to GitHub Actions tab
- [ ] Click "Deploy to ECS" workflow
- [ ] Click "Run workflow" button
- [ ] In the dialog:
  - [ ] Image tag: `latest` (or specific timestamped tag)
  - [ ] Services: `both` (or specific service)
  - [ ] Click green "Run workflow" button

### Monitor Deployment
- [ ] Deployment job starts in GitHub Actions
- [ ] Watch for stages:
  - [ ] ✅ AWS credentials configured via OIDC
  - [ ] ✅ Task definition fetched from ECS
  - [ ] ✅ New revision registered
  - [ ] ✅ Service updated
  - [ ] ✅ Service stabilized (5 min wait)
- [ ] Deployment completes successfully

### Verify Services in ECS
- [ ] Log into AWS Console
- [ ] Go to ECS > Clusters > `projet-cloud-cluster`
- [ ] Verify services:
  - [ ] Backend service shows updated task definition revision
  - [ ] Frontend service shows updated task definition revision
  - [ ] Both services show desired = running tasks
  - [ ] Both services show healthy status

### Verify Application Access
- [ ] Get ALB DNS name from AWS EC2 > Load Balancers
- [ ] Test Frontend:
  - [ ] Navigate to `http://alb-dns-name/`
  - [ ] Frontend loads successfully
  - [ ] No 502/503 errors
- [ ] Test Backend:
  - [ ] Navigate to `http://alb-dns-name:8000/health` (or health endpoint)
  - [ ] Backend responds with 200 status
  - [ ] API is accessible

---

## Phase 8: Post-Deployment Validation 🔍

### Application Health Checks
- [ ] Login page loads: ✅
- [ ] API endpoints respond: ✅
- [ ] Database queries work: ✅
- [ ] File uploads work: ✅
- [ ] Scoring engine works: ✅
- [ ] No error messages in logs: ✅

### CloudWatch Monitoring
- [ ] Go to CloudWatch > Logs
- [ ] Check ECS logs for errors:
  - [ ] Backend service logs: No errors
  - [ ] Frontend service logs: No errors
- [ ] Check metrics:
  - [ ] CPU usage normal (< 70%)
  - [ ] Memory usage normal (< 80%)
  - [ ] Network in/out reasonable

### GitHub Actions History
- [ ] Go to Actions tab
- [ ] Verify recent runs:
  - [ ] Latest CI/CD run: ✅ Passed
  - [ ] Latest Deploy run: ✅ Passed
- [ ] No failed workflows in last 24h

---

## Phase 9: Documentation & Handoff 📝

### Create Runbooks
- [ ] Created deployment runbook
- [ ] Created troubleshooting guide
- [ ] Created rollback procedure
- [ ] Shared with team

### Team Communication
- [ ] Team notified of new CI/CD pipeline
- [ ] Team given access to documentation
- [ ] Team trained on:
  - [ ] How to push code
  - [ ] How to monitor pipeline
  - [ ] How to trigger deployment
  - [ ] How to rollback if needed

### Update README
- [ ] Main project README updated with CI/CD info
- [ ] Contributing guidelines updated
- [ ] Deployment procedure documented

---

## Phase 10: Final Sign-Off ✨

### All Checks Complete
- [ ] Phase 1 (AWS): ✅ Complete
- [ ] Phase 2 (GitHub): ✅ Complete
- [ ] Phase 3 (Local Testing): ✅ Complete
- [ ] Phase 4 (First Run): ✅ Complete
- [ ] Phase 5 (ECR Verification): ✅ Complete
- [ ] Phase 6 (Documentation): ✅ Complete
- [ ] Phase 7 (Deployment): ✅ Complete
- [ ] Phase 8 (Validation): ✅ Complete
- [ ] Phase 9 (Documentation): ✅ Complete

### Sign-Off
- [ ] **Deployment Date:** _______________
- [ ] **Completed By:** _______________
- [ ] **Reviewed By:** _______________
- [ ] **Approved By:** _______________

### Next Steps
- [ ] Schedule daily monitoring for first week
- [ ] Plan optimization based on metrics
- [ ] Update security group rules if needed
- [ ] Plan capacity scaling if needed

---

## 🆘 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Pipeline fails at security scan | Check GitHub Actions logs, review security issues in code |
| Tests fail | Run tests locally, fix issues, push again |
| ECR push fails | Verify AWS role, check IAM permissions, rerun setup script |
| Deployment timeout | Check ECS logs, verify database connectivity, check networking |
| Services not healthy | Check task definition, CloudWatch logs, security groups |
| API not accessible | Verify ALB, security groups, health check endpoint |

---

## 📞 Support Contacts

- **DevOps Lead:** _______________
- **AWS Administrator:** _______________
- **Backend Developer:** _______________
- **Frontend Developer:** _______________

---

## 📊 Deployment Statistics

- **Pipeline Duration:** ___________ minutes
- **Images Pushed:** ___________ (backend + frontend)
- **Deployment Duration:** ___________ minutes
- **Zero Downtime:** ✅ Yes / ❌ No
- **Issues Found:** ___________ (count)
- **Issues Resolved:** ___________ (count)

---

**Status:** ✅ Ready for Production  
**Last Updated:** June 14, 2026

