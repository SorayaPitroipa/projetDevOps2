# Infrastructure Setup Guide

This directory contains infrastructure-as-code and configuration for deploying the CEquality credit scoring application to AWS.

## 📁 Files Overview

- **`cloudformation-template.yaml`** - CloudFormation template for automated AWS infrastructure setup
- **`setup-database.sql`** - Database initialization script (if needed)

## 🚀 Quick Start (Choose One)

### Option A: Automated Setup with CloudFormation (Recommended)

CloudFormation automates the creation of all AWS resources in a single command.

**Prerequisites:**
- AWS CLI installed: https://aws.amazon.com/cli/
- AWS credentials configured: `aws configure`

**Deploy:**

```bash
# Set your password (make it strong!)
export DB_PASSWORD="YourStrongPassword123!"

# Create the stack
aws cloudformation create-stack \
  --stack-name cequality-infrastructure \
  --template-body file://infra/cloudformation-template.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=production \
    ParameterKey=DBMasterPassword,ParameterValue=$DB_PASSWORD \
    ParameterKey=ECSClusterName,ParameterValue=projet-cloud-cluster \
  --region eu-west-1 \
  --capabilities CAPABILITY_NAMED_IAM

# Monitor creation (takes ~10-15 minutes)
aws cloudformation describe-stacks \
  --stack-name cequality-infrastructure \
  --query 'Stacks[0].StackStatus' \
  --region eu-west-1 \
  --watch

# Get outputs when complete
aws cloudformation describe-stacks \
  --stack-name cequality-infrastructure \
  --query 'Stacks[0].Outputs' \
  --region eu-west-1 \
  --output table
```

**What gets created:**
- ✅ RDS PostgreSQL Database (`cloud_projet`)
- ✅ ECS Cluster (`projet-cloud-cluster`)
- ✅ Application Load Balancer with 2 target groups
- ✅ Security Groups for ALB, ECS, and RDS
- ✅ CloudWatch Log Groups
- ✅ ECR Repositories

**Output Values:** The CloudFormation outputs provide:
- Database endpoint for `APPVAR_DATABASE_URL`
- ALB DNS name to access your application
- Target group ARNs for ECS service configuration

---

### Option B: Manual Setup via AWS Console

Follow the detailed step-by-step guide in [../docs/AWS_DEPLOYMENT_GUIDE.md](../docs/AWS_DEPLOYMENT_GUIDE.md)

This option gives you more control and lets you understand each component.

---

## 📋 Configuration Checklist

After infrastructure setup (either method), follow [../docs/DEPLOYMENT_CHECKLIST.md](../docs/DEPLOYMENT_CHECKLIST.md) to:
1. Configure GitHub Secrets and Variables
2. Verify ECS Services
3. Deploy your application
4. Test the deployment

---

## 🔧 GitHub Configuration Helper

Use the provided script to configure GitHub automatically:

```bash
# Make script executable
chmod +x scripts/setup-github-config.sh

# Run interactive setup
./scripts/setup-github-config.sh
```

This script will prompt you for:
- AWS region and ECS cluster names
- Application variables (admin emails, Google OAuth ID, etc.)
- Application secrets (JWT secret, database URL, etc.)
- DockerHub credentials

---

## 🏗️ Architecture

```
                          ┌─────────────────┐
                          │  GitHub Actions │
                          │   (CI/CD)       │
                          └────────┬────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                ▼                  ▼                  ▼
            DockerHub            ECR              ECR
         (public builds)      (project-cloud-  (project-cloud-
                              backend)         frontend)
                                   │                  │
                                   └──────────┬───────┘
                                              ▼
                            ┌─────────────────────────────┐
                            │  ALB                        │
                            │  (Application Load Balancer)│
                            └──────────┬──────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                                     ▼
              Port 80 (HTTP)                        Port 8000 (HTTP)
                    │                                     │
         ┌──────────┴──────────┐            ┌────────────┴────────────┐
         ▼                     ▼            ▼                         ▼
    ┌─────────┐           ┌─────────┐  ┌──────────┐            ┌──────────┐
    │ Frontend│           │Backend  │  │ Frontend │            │ Backend  │
    │Service  │           │Service  │  │Target Gr │            │Target Gr │
    │(Task)   │           │(Task)   │  │oup 80    │            │oup 8000  │
    └────┬────┘           └────┬────┘  └──────────┘            └──────────┘
         │                     │
         └──────────┬──────────┘
                    ▼
            ┌───────────────────┐
            │  RDS PostgreSQL   │
            │ (cloud_projet db) │
            └───────────────────┘
```

---

## 📊 Cost Estimation

**Free Tier Eligible (First 12 months):**
- ✅ RDS db.t3.micro PostgreSQL (750 hours/month)
- ✅ ECS Fargate (7 days free after signup)
- ✅ ALB (first 750 hours)
- ✅ Data transfer (up to 100 GB/month)

**Estimated Monthly Cost (after free tier):**
- RDS: ~$15-20/month
- ECS Fargate: ~$10-30/month (depending on task count/duration)
- ALB: ~$20/month (base) + $0.006/LCU-hour
- Total: ~$50-80/month (minimal usage)

---

## 🔐 Security Considerations

### Before Production Deployment

- [ ] **RDS Security:**
  - [ ] Restrict publicly accessible to private subnets only
  - [ ] Enable encryption at rest (default: yes)
  - [ ] Enable automated backups (default: 7 days)
  - [ ] Use IAM database authentication (optional)

- [ ] **ALB Security:**
  - [ ] Enable HTTPS with ACM certificate
  - [ ] Redirect HTTP to HTTPS
  - [ ] Set WAF rules (optional)

- [ ] **ECS Security:**
  - [ ] Use task execution role with least privileges
  - [ ] Store secrets in AWS Secrets Manager (not env vars)
  - [ ] Enable ECS Exec for debugging (optional)

- [ ] **GitHub Security:**
  - [ ] Rotate secrets periodically
  - [ ] Audit OIDC role permissions
  - [ ] Enable branch protection on main

---

## 🆘 Troubleshooting

### CloudFormation Stack Creation Failed

```bash
# View error details
aws cloudformation describe-stack-events \
  --stack-name cequality-infrastructure \
  --region eu-west-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]' \
  --output table

# Delete failed stack (cleanup)
aws cloudformation delete-stack \
  --stack-name cequality-infrastructure \
  --region eu-west-1
```

### RDS Database Connection Fails

1. Verify security group allows traffic on port 5432
2. Check RDS is publicly accessible (if needed)
3. Verify password is correct
4. Test connection:
   ```bash
   psql -h <rds-endpoint> -U postgres -d cloud_projet
   ```

### ECS Tasks Failing to Start

1. Check CloudWatch logs: `/ecs/projet-cloud-backend`, `/ecs/projet-cloud-frontend`
2. Verify environment variables are set in task definition
3. Check ECR images exist: `aws ecr describe-images --repository-name projet-cloud-backend`
4. View task logs in AWS console for error details

---

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [CloudFormation User Guide](https://docs.aws.amazon.com/cloudformation/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

---

## 📝 Next Steps

1. **Deploy Infrastructure:** Use CloudFormation or manual setup
2. **Configure GitHub:** Use `scripts/setup-github-config.sh` or manual steps
3. **Deploy Application:** Follow [../docs/DEPLOYMENT_CHECKLIST.md](../docs/DEPLOYMENT_CHECKLIST.md)
4. **Monitor & Scale:** Set up CloudWatch alarms and auto-scaling

---

**Created:** June 2024  
**Last Updated:** June 14, 2024  
**Maintained By:** Daniel Glorieux
