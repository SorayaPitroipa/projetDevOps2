# AWS Deployment Checklist for CEquality Project

This checklist tracks your progress through the AWS deployment process.

## Phase 1: RDS Database Setup ✅

- [ ] AWS Account ready with permissions
- [ ] Navigate to AWS RDS Console
- [ ] Create new PostgreSQL 15.x database instance
  - [ ] DB Instance Identifier: `cequality-db`
  - [ ] Master Username: `postgres`
  - [ ] Master Password: *(strong password)*
  - [ ] Database Name: `cloud_projet`
  - [ ] Instance Class: `db.t3.micro`
  - [ ] Storage: 20 GiB
  - [ ] VPC: Default
  - [ ] Publicly Accessible: Yes
  - [ ] Backup Retention: 7 days
- [ ] Wait for RDS status: "Available" (~5-10 minutes)
- [ ] Get RDS Endpoint: `cequality-db.xxxxx.eu-west-1.rds.amazonaws.com`
- [ ] Create connection string:
  ```
  ******cequality-db.xxxxx.eu-west-1.rds.amazonaws.com:5432/cloud_projet
  ```
- [ ] Save as GitHub Secret: `APPVAR_DATABASE_URL`

**RDS Endpoint:** `_________________________________`

---

## Phase 2: ECS Cluster Setup ✅

- [ ] Navigate to AWS ECS Console
- [ ] Create new cluster
  - [ ] Cluster Name: `projet-cloud-cluster`
  - [ ] Infrastructure: FARGATE
  - [ ] Enable CloudWatch Container Insights: Yes
- [ ] Wait for cluster status: "Active"

**ECS Cluster ARN:** `_________________________________`

---

## Phase 3: ALB & Target Groups Setup ✅

- [ ] Navigate to AWS EC2 Load Balancers Console
- [ ] Create Application Load Balancer
  - [ ] Name: `projet-cloud-alb`
  - [ ] Scheme: Internet-facing
  - [ ] VPC: Default
  - [ ] Subnets: Select all (minimum 2)
  - [ ] Security Group: Create new
    - [ ] Name: `alb-security-group`
    - [ ] Inbound Port 80 (HTTP): Allow from 0.0.0.0/0
    - [ ] Inbound Port 443 (HTTPS): Allow from 0.0.0.0/0 (optional)

- [ ] Create Target Groups:
  - [ ] Frontend Target Group
    - [ ] Name: `projet-frontend-tg`
    - [ ] Protocol: HTTP, Port: 80
    - [ ] VPC: Default
    - [ ] Health Check Path: `/`
    - [ ] Interval: 30s, Timeout: 5s
  - [ ] Backend Target Group
    - [ ] Name: `projet-cloud-backend-tg`
    - [ ] Protocol: HTTP, Port: 8000
    - [ ] VPC: Default
    - [ ] Health Check Path: `/health`
    - [ ] Interval: 30s, Timeout: 5s

- [ ] Add Listeners:
  - [ ] Listener 1: Port 80 → Forward to `projet-frontend-tg`
  - [ ] Listener 2: Port 8000 → Forward to `projet-cloud-backend-tg`

- [ ] Wait for ALB status: "Active"
- [ ] Get ALB DNS Name from ALB details

**ALB DNS Name:** `_________________________________`

**ALB Access URL:** `http://_________________________________`

---

## Phase 4: Security Groups for ECS ✅

- [ ] Create ECS Security Group
  - [ ] Name: `ecs-security-group`
  - [ ] Inbound Rule 1: Port 8000 from ALB Security Group (Backend)
  - [ ] Inbound Rule 2: Port 80 from ALB Security Group (Frontend)

**ECS Security Group ID:** `_________________________________`

---

## Phase 5: Task Definitions ✅

### Backend Task Definition

- [ ] Navigate to AWS ECS Task Definitions
- [ ] Create new task definition
  - [ ] Family Name: `projet-cloud-backend`
  - [ ] Launch Type: FARGATE
  - [ ] CPU: 256 (.25 vCPU)
  - [ ] Memory: 512 MB
  - [ ] Task Role: `github-actions-deploy-daniel`
  - [ ] Execution Role: ecsTaskExecutionRole (create if needed)

- [ ] Add Container
  - [ ] Container Name: `backend`
  - [ ] Image URI: `411474713112.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-backend:latest`
  - [ ] Container Port: 8000
  - [ ] Environment Variables:
    - [ ] `AWS_REGION` = `eu-west-1`
    - [ ] `GOOGLE_CLIENT_ID` = *(from GitHub Variables)*
    - [ ] `ADMIN_EMAILS` = *(from GitHub Variables)*
  - [ ] Log Group: `/ecs/projet-cloud-backend`

- [ ] Create Task Definition

### Frontend Task Definition

- [ ] Create new task definition
  - [ ] Family Name: `projet-cloud-frontend`
  - [ ] Launch Type: FARGATE
  - [ ] CPU: 256 (.25 vCPU)
  - [ ] Memory: 512 MB

- [ ] Add Container
  - [ ] Container Name: `frontend`
  - [ ] Image URI: `411474713112.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-frontend:latest`
  - [ ] Container Port: 80
  - [ ] Environment Variables:
    - [ ] `VITE_GOOGLE_CLIENT_ID` = *(from GitHub Variables)*
  - [ ] Log Group: `/ecs/projet-cloud-frontend`

- [ ] Create Task Definition

---

## Phase 6: ECS Services ✅

### Backend Service

- [ ] Open ECS Cluster: `projet-cloud-cluster`
- [ ] Create new service
  - [ ] Launch Type: FARGATE
  - [ ] Task Definition: `projet-cloud-backend`
  - [ ] Service Name: `projet-cloud-backend-service`
  - [ ] Desired Count: 1
  - [ ] VPC: Default
  - [ ] Subnets: All
  - [ ] Security Group: `ecs-security-group`
  - [ ] Load Balancer: `projet-cloud-alb`
  - [ ] Container: `backend:8000`
  - [ ] Target Group: `projet-cloud-backend-tg`

- [ ] Create Service

### Frontend Service

- [ ] Create new service (same cluster)
  - [ ] Task Definition: `projet-cloud-frontend`
  - [ ] Service Name: `projet-cloud-frontend-service`
  - [ ] Desired Count: 1
  - [ ] Container: `frontend:80`
  - [ ] Target Group: `projet-frontend-tg`

- [ ] Create Service

---

## Phase 7: GitHub Configuration ✅

### GitHub Variables

Navigate to: **Settings → Secrets and variables → Actions → Variables**

- [ ] `AWS_REGION` = `eu-west-1`
- [ ] `ECS_CLUSTER` = `projet-cloud-cluster`
- [ ] `ECS_BACKEND_SERVICE` = `projet-cloud-backend-service`
- [ ] `ECS_FRONTEND_SERVICE` = `projet-cloud-frontend-service`
- [ ] `APPVAR_ADMIN_EMAILS` = `sorayapitroipa9@gmail.com`
- [ ] `APPVAR_GOOGLE_CLIENT_ID` = *(your Google OAuth client ID)*
- [ ] `APPVAR_MODEL_S3_BUCKET` = *(if using S3 for ML models)*
- [ ] `APPVAR_MODEL_S3_KEY` = *(if using S3 for ML models)*

### GitHub Secrets

Navigate to: **Settings → Secrets and variables → Actions → Secrets**

- [ ] `AWS_ROLE_TO_ASSUME` = `arn:aws:iam::411474713112:role/github-actions-deploy-daniel`
- [ ] `DOCKERHUB_USERNAME` = `danielglorieux`
- [ ] `DOCKERHUB_TOKEN` = *(your DockerHub token)*
- [ ] `APPVAR_JWT_SECRET` = *(generate: `openssl rand -base64 32`)*
- [ ] `APPVAR_DATABASE_URL` = *(PostgreSQL connection string from Phase 1)*

**Run setup script (optional):** `bash scripts/setup-github-config.sh`

---

## Phase 8: CI/CD Pipeline Verification ✅

- [ ] Push to main branch:
  ```bash
  git add docs/AWS_DEPLOYMENT_GUIDE.md infra/ scripts/setup-github-config.sh
  git commit -m "docs: add AWS deployment guides and infrastructure templates"
  git push origin main
  ```

- [ ] Verify GitHub Actions triggers automatically:
  - [ ] Go to GitHub Actions tab
  - [ ] Check CI/CD workflow runs
  - [ ] Verify all steps pass:
    - [ ] Security scans (trufflehog, pip-audit)
    - [ ] Backend tests (pytest)
    - [ ] Frontend build
    - [ ] Docker image builds
    - [ ] ECR push (if AWS_ROLE_TO_ASSUME is set)

**CI/CD Workflow URL:** `https://github.com/DanielGlorieux/projetDevOps2/actions`

---

## Phase 9: Deployment ✅

- [ ] **Wait for CI/CD to complete successfully** (should push images to ECR)

- [ ] Manually trigger deployment:
  - [ ] Go to GitHub Actions → **Deploy to ECS**
  - [ ] Click **Run workflow**
  - [ ] Select:
    - [ ] Image tag: `latest`
    - [ ] Services: `both`
  - [ ] Click **Run workflow**
  - [ ] Wait for deployment to complete (~2-3 minutes)

- [ ] Verify deployment in AWS:
  - [ ] Go to ECS Cluster: `projet-cloud-cluster`
  - [ ] Check services status:
    - [ ] `projet-cloud-backend-service`: Running
    - [ ] `projet-cloud-frontend-service`: Running
  - [ ] Check target groups in EC2:
    - [ ] `projet-frontend-tg`: Targets healthy
    - [ ] `projet-cloud-backend-tg`: Targets healthy

---

## Phase 10: Application Testing ✅

- [ ] Access application via ALB:
  - [ ] Frontend: `http://projet-cloud-alb-xxxxx.eu-west-1.elb.amazonaws.com`
  - [ ] Backend API: `http://projet-cloud-alb-xxxxx.eu-west-1.elb.amazonaws.com:8000`
  - [ ] Backend Health: `http://projet-cloud-alb-xxxxx.eu-west-1.elb.amazonaws.com:8000/health`

- [ ] Test frontend:
  - [ ] Page loads
  - [ ] Google OAuth login works
  - [ ] Can upload Wave PDF
  - [ ] Can submit form

- [ ] Test backend:
  - [ ] API responds to requests
  - [ ] Database connection works
  - [ ] Health check endpoint returns 200

- [ ] Check CloudWatch logs:
  - [ ] `/ecs/projet-cloud-backend`: No error logs
  - [ ] `/ecs/projet-cloud-frontend`: No error logs

---

## Phase 11: Optional - Custom Domain (Route53) ✅

- [ ] Create or verify domain in Route53
- [ ] Create Alias record:
  - [ ] Record Name: `cequality.yourdomain.com` (or similar)
  - [ ] Record Type: A
  - [ ] Alias: Yes
  - [ ] Alias Target: `projet-cloud-alb-xxxxx.eu-west-1.elb.amazonaws.com`
- [ ] Wait for DNS propagation (~5 minutes)
- [ ] Access via custom domain

**Custom Domain:** `_________________________________`

---

## Phase 12: Monitoring & Cleanup ✅

- [ ] Set up CloudWatch Alarms:
  - [ ] ALB Target Group Health
  - [ ] ECS CPU/Memory utilization
  - [ ] RDS CPU/Storage

- [ ] Review AWS costs:
  - [ ] RDS free tier status
  - [ ] ECS Fargate pricing
  - [ ] ALB pricing
  - [ ] Data transfer costs

- [ ] Document for team:
  - [ ] Deployment procedure
  - [ ] Troubleshooting guide
  - [ ] Cost optimization notes

---

## Troubleshooting Log

### Issue 1: ___________________________________
**Symptom:** 

**Solution:** 

**Status:** [ ] Resolved

---

### Issue 2: ___________________________________
**Symptom:** 

**Solution:** 

**Status:** [ ] Resolved

---

## Completion Status

- [ ] All AWS infrastructure created and healthy
- [ ] GitHub Actions configured with all secrets/variables
- [ ] CI/CD pipeline working (builds and pushes to ECR)
- [ ] Manual deployment workflow functional
- [ ] Services running and healthy in ECS
- [ ] Application accessible via ALB
- [ ] Frontend and backend tested
- [ ] Custom domain configured (optional)
- [ ] Monitoring and alarms set up
- [ ] Team documentation complete

**Deployment Completed:** `___________________` (date)

**Deployed By:** `___________________` (name)

**Deployment Notes:**

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________

