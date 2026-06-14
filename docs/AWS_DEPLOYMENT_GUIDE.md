# AWS Deployment Guide for CEquality Project

This guide walks you through deploying the CEquality credit scoring application to AWS ECS with an Application Load Balancer (ALB), following the pattern you successfully used for the microscore project.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Step-by-Step AWS Setup](#step-by-step-aws-setup)
4. [GitHub Configuration](#github-configuration)
5. [Deployment Workflow](#deployment-workflow)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- ✅ AWS Account with IAM role configured: `arn:aws:iam::411474713112:role/github-actions-deploy-daniel`
- ✅ DockerHub account configured (already set in GitHub Secrets)
- ✅ GitHub repository with Secrets/Variables configured
- ✅ Permission to create resources: ECS, RDS, ALB, ECR (already enabled via OIDC role)

---

## Architecture Overview

```
GitHub Actions (CI/CD)
    ↓
    ├─→ [Test & Build] (Backend: pytest, Frontend: npm build)
    ├─→ [Push to DockerHub] (Latest images)
    ├─→ [Push to ECR] (AWS Container Registry)
    └─→ [Manual Trigger: Deploy to ECS]
             ↓
    Application Load Balancer (ALB)
    ├─→ :80 → Frontend (Nginx)  [Target Group: project-frontend-tg]
    └─→ :8000 → Backend (FastAPI) [Target Group: projet-cloud-backend-tg]
             ↓
         ECS Cluster (projet-cloud-cluster)
         ├─→ Backend Service
         └─→ Frontend Service
             ↓
         RDS PostgreSQL Database
```

---

## Step-by-Step AWS Setup

### **Phase 1: Create RDS PostgreSQL Database**

1. **Open AWS Console** → **RDS** → **Databases** → **Create database**

2. **Database Configuration:**
   - **Engine:** PostgreSQL
   - **Version:** 15.x (or later)
   - **DB Instance Identifier:** `cequality-db`
   - **Master Username:** `postgres`
   - **Master Password:** *[Create a strong password and save it]*
   - **Instance Class:** `db.t3.micro` (free tier, suitable for testing)
   - **Storage:** `20 GiB` (default)

3. **Connectivity:**
   - **VPC:** Default VPC
   - **Publicly Accessible:** Yes (for now; restrict later)
   - **VPC Security Group:** Create new → Name: `rds-security-group`
   - **Database Port:** 5432

4. **Additional Configuration:**
   - **Initial Database Name:** `cloud_projet`
   - **Backup retention period:** 7 days
   - **Enable encryption:** Yes (default)

5. **Create Database** → Wait for status to be "Available" (~5-10 minutes)

6. **Get Connection String:**
   - Open the RDS database details
   - Find the **Endpoint** (format: `cequality-db.xxxxx.eu-west-1.rds.amazonaws.com`)
   - Create connection string:
     ```
     ******cequality-db.xxxxx.eu-west-1.rds.amazonaws.com:5432/cloud_projet
     ```
   - **Save this for GitHub Secrets** → `APPVAR_DATABASE_URL`

---

### **Phase 2: Create ECS Cluster**

1. **Open AWS Console** → **ECS** → **Clusters** → **Create cluster**

2. **Cluster Configuration:**
   - **Cluster Name:** `projet-cloud-cluster`
   - **Infrastructure:** AWS Fargate (serverless, no EC2 to manage)
   - **Networking:** Default VPC, select all Availability Zones
   - **CloudWatch Container Insights:** Enable (optional but recommended)

3. **Create Cluster** → Wait for status "Active"

---

### **Phase 3: Create ALB (Application Load Balancer)**

1. **Open AWS Console** → **EC2** → **Load Balancers** → **Create load balancer**

2. **Select Load Balancer Type:** Application Load Balancer

3. **Basic Configuration:**
   - **Name:** `projet-cloud-alb`
   - **Scheme:** Internet-facing
   - **IP Address Type:** IPv4
   - **VPC:** Default VPC
   - **Availability Zones:** Select all (at least 2)

4. **Security Groups:**
   - Create new security group:
     - **Name:** `alb-security-group`
     - **Inbound Rules:**
       - Port 80 (HTTP): Allow from 0.0.0.0/0
       - Port 443 (HTTPS): Allow from 0.0.0.0/0 (optional, if using SSL)

5. **Listeners and Routing:**
   - **Listener 1:** HTTP:80 → Forward to target group
   - **Create Target Group 1 (Frontend):**
     - **Name:** `projet-frontend-tg`
     - **Protocol:** HTTP
     - **Port:** 80
     - **VPC:** Default
     - **Health Check:** Path `/`, Interval 30s

   - **Listener 2 (Backend):** HTTP:8000 → Forward to target group
   - **Create Target Group 2 (Backend):**
     - **Name:** `projet-cloud-backend-tg`
     - **Protocol:** HTTP
     - **Port:** 8000
     - **VPC:** Default
     - **Health Check:** Path `/health`, Interval 30s, Timeout 5s

6. **Create Load Balancer** → Wait for status "Active"

7. **Get ALB DNS Name:**
   - Open ALB details
   - Find **DNS Name** (format: `projet-cloud-alb-xxxxx.eu-west-1.elb.amazonaws.com`)
   - **Access your app via:** `http://projet-cloud-alb-xxxxx.eu-west-1.elb.amazonaws.com`
   - *(Optional: Configure Route53 or your DNS provider to point a custom domain here)*

---

### **Phase 4: Create ECS Task Definitions**

#### **Task Definition 1: Backend**

1. **Open AWS Console** → **ECS** → **Task Definitions** → **Create new task definition**

2. **Basic Configuration:**
   - **Family Name:** `projet-cloud-backend`
   - **Launch Type:** FARGATE
   - **Operating System:** Linux
   - **CPU:** 256 (.25 vCPU)
   - **Memory:** 512 MB
   - **Task Role:** `github-actions-deploy-daniel` (your OIDC role)
   - **Task Execution Role:** Create new ecsTaskExecutionRole or use existing

3. **Add Container:**
   - **Container Name:** `backend`
   - **Image URI:** `411474713112.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-backend:latest`
   - **Essential:** Yes
   - **Port Mappings:** 
     - **Container Port:** 8000
     - **Protocol:** TCP
   - **Environment Variables:**
     - `AWS_REGION` = `eu-west-1`
     - `GOOGLE_CLIENT_ID` = *(from your GitHub Variables)*
     - `ADMIN_EMAILS` = *(from your GitHub Variables)*
     - `DATABASE_URL` = *(from your GitHub Secrets)*
     - `JWT_SECRET` = *(from your GitHub Secrets)*

4. **Logging:** 
   - CloudWatch Log Group: `/ecs/projet-cloud-backend`

5. **Create Task Definition**

---

#### **Task Definition 2: Frontend**

1. **Create new task definition:**
   - **Family Name:** `projet-cloud-frontend`
   - **Launch Type:** FARGATE
   - **CPU:** 256 (.25 vCPU)
   - **Memory:** 512 MB

2. **Add Container:**
   - **Container Name:** `frontend`
   - **Image URI:** `411474713112.dkr.ecr.eu-west-1.amazonaws.com/projet-cloud-frontend:latest`
   - **Port Mappings:**
     - **Container Port:** 80
     - **Protocol:** TCP
   - **Environment Variables:**
     - `VITE_GOOGLE_CLIENT_ID` = *(from your GitHub Variables)*

3. **Logging:**
   - CloudWatch Log Group: `/ecs/projet-cloud-frontend`

4. **Create Task Definition**

---

### **Phase 5: Create ECS Services**

#### **Service 1: Backend Service**

1. **Open AWS Console** → **ECS** → **Clusters** → **projet-cloud-cluster** → **Create**

2. **Service Configuration:**
   - **Launch Type:** FARGATE
   - **Task Definition Family:** `projet-cloud-backend`
   - **Task Definition Revision:** Select latest
   - **Service Name:** `projet-cloud-backend-service`
   - **Desired Count:** 1 (start small, scale later)

3. **Networking:**
   - **VPC:** Default
   - **Subnets:** Select all
   - **Security Groups:** Create new → Allow port 8000 from ALB security group

4. **Load Balancing:**
   - **Load Balancer Type:** Application Load Balancer
   - **Load Balancer Name:** `projet-cloud-alb`
   - **Container:** `backend:8000`
   - **Target Group:** `projet-cloud-backend-tg`

5. **Auto Scaling:** Skip for now (configure manually later if needed)

6. **Create Service**

---

#### **Service 2: Frontend Service**

1. **Create service (similar steps):**
   - **Service Name:** `projet-cloud-frontend-service`
   - **Task Definition:** `projet-cloud-frontend`
   - **Desired Count:** 1
   - **Container:** `frontend:80`
   - **Target Group:** `projet-frontend-tg`

2. **Create Service**

---

## GitHub Configuration

### **Update GitHub Variables**

Navigate to **Settings** → **Secrets and variables** → **Actions** → **Variables tab**

```bash
# Cluster & Service Names (MUST match AWS)
ECS_CLUSTER = projet-cloud-cluster
ECS_BACKEND_SERVICE = projet-cloud-backend-service
ECS_FRONTEND_SERVICE = projet-cloud-frontend-service

# Application Variables
APPVAR_ADMIN_EMAILS = sorayapitroipa9@gmail.com
APPVAR_GOOGLE_CLIENT_ID = 126565436796-q33qd1s73kr2tb2m0b2ltqtogsu9ehet.apps.googleusercontent.com
APPVAR_MODEL_S3_BUCKET = (optional, if using S3)
APPVAR_MODEL_S3_KEY = (optional, if using S3)

# AWS Configuration
AWS_REGION = eu-west-1
```

### **Update GitHub Secrets**

Navigate to **Settings** → **Secrets and variables** → **Actions** → **Secrets tab**

```bash
# AWS OIDC
AWS_ROLE_TO_ASSUME = arn:aws:iam::411474713112:role/github-actions-deploy-daniel

# DockerHub
DOCKERHUB_USERNAME = danielglorieux
DOCKERHUB_TOKEN = (your DockerHub token - keep this secret!)

# Application Secrets
APPVAR_JWT_SECRET = (generate strong random: openssl rand -base64 32)
APPVAR_DATABASE_URL = ******cequality-db.xxxxx.eu-west-1.rds.amazonaws.com:5432/cloud_projet
```

**To generate JWT Secret:**
```bash
openssl rand -base64 32
# Example output: AbCdEfGhIjKlMnOpQrStUvWxYz1234567890+/=
```

---

## Deployment Workflow

### **Automatic Deployment (On Push to Main)**

1. **Push code to main branch:**
   ```bash
   git add .
   git commit -m "Deploy to ECS"
   git push origin main
   ```

2. **GitHub Actions Automatically:**
   - Runs security scans
   - Tests backend (pytest)
   - Builds frontend
   - Builds Docker images
   - Pushes to DockerHub & ECR

3. **Manual Step: Trigger ECS Deployment**
   - Go to **Actions** tab in GitHub
   - Click **Deploy to ECS** workflow
   - Click **Run workflow**
   - Select:
     - **Image tag:** `latest`
     - **Services:** `both`
   - Click **Run workflow**
   - Wait for deployment to complete (~2-3 minutes)

### **Manual Deployment (Anytime)**

If you just want to re-deploy without code changes:
- Go to **Actions** → **Deploy to ECS** → **Run workflow**
- Select services and image tag
- Click **Run**

---

## Troubleshooting

### **Common Issues and Solutions**

#### **Issue: ECS Service stuck in "RUNNING" but tasks failing**
- **Check Task Logs:**
  - Go to **ECS** → **Clusters** → **projet-cloud-cluster** → **Services** → Click service
  - Click **Tasks** tab
  - Click task name → **Container details** → **Log Group**
  - Check CloudWatch logs for errors
- **Common causes:**
  - Missing environment variables
  - Database connection string incorrect
  - ECR image tag doesn't exist

#### **Issue: ALB returning 502 Bad Gateway**
- **Check Target Group Health:**
  - Go to **EC2** → **Target Groups**
  - Click target group → **Targets** tab
  - Verify targets are marked "Healthy"
  - Check health check settings (interval, timeout, path)
- **Check ECS Service:**
  - Verify service is running
  - Check task logs for startup errors
  - Verify security groups allow traffic from ALB

#### **Issue: GitHub workflow fails at "Configure AWS via OIDC"**
- **Verify:**
  - `AWS_ROLE_TO_ASSUME` secret is set correctly
  - GitHub OIDC provider is configured in AWS IAM
  - Role has permissions for ECS, ECR, task definitions

#### **Issue: Docker image not found in ECR**
- **Solution:**
  - Push to ECR step might have failed
  - Check previous CI/CD workflow logs
  - Manually re-run "Build Docker images" → "Push images to AWS ECR" step

---

## Next Steps

1. ✅ Complete Phase 1-5 of AWS setup above
2. ✅ Update GitHub Variables and Secrets
3. ✅ Verify ECR repositories exist (created automatically on first CI/CD run)
4. ✅ Push to main branch to trigger CI/CD
5. ✅ Manually trigger "Deploy to ECS" workflow
6. ✅ Monitor deployment in GitHub Actions and AWS ECS
7. ✅ Access application via ALB DNS name

---

## Additional Notes

- **Cost Optimization:** The `db.t3.micro` and Fargate `t3.micro` instances qualify for AWS free tier. Monitor costs after 12 months.
- **SSL/HTTPS:** To add SSL, create ACM certificate and configure ALB listener for HTTPS
- **Auto Scaling:** After verifying stability, configure ECS service auto-scaling based on CPU/memory
- **Custom Domain:** Use Route53 or external DNS provider to point custom domain to ALB DNS name
- **Backups:** RDS automated backups are configured; set backup retention as needed

---

For questions or issues, refer to the [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/) and [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/).
