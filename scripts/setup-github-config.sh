#!/bin/bash
# =============================================================================
# AWS Deployment Configuration Helper
# =============================================================================
# This script helps you configure GitHub Secrets and Variables for AWS deployment
# Usage: ./scripts/setup-github-config.sh
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}AWS Deployment Configuration Helper${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Install it from: https://cli.github.com"
    exit 1
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub.${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q)
echo -e "${GREEN}Repository: $REPO${NC}"
echo ""

# Function to set a GitHub variable
set_variable() {
    local var_name=$1
    local var_value=$2
    echo -e "${YELLOW}Setting variable: $var_name${NC}"
    gh variable set "$var_name" --body "$var_value" --repo "$REPO" 2>/dev/null || {
        echo -e "${RED}Failed to set variable $var_name${NC}"
        return 1
    }
    echo -e "${GREEN}✓ $var_name set${NC}"
}

# Function to set a GitHub secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    echo -e "${YELLOW}Setting secret: $secret_name${NC}"
    gh secret set "$secret_name" --body "$secret_value" --repo "$REPO" 2>/dev/null || {
        echo -e "${RED}Failed to set secret $secret_name${NC}"
        return 1
    }
    echo -e "${GREEN}✓ $secret_name set${NC}"
}

# Configuration items
echo -e "${BLUE}=== GITHUB VARIABLES ===${NC}"
echo "These are non-sensitive configuration values"
echo ""

# AWS Configuration Variables
read -p "AWS Region (default: eu-west-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-eu-west-1}
set_variable "AWS_REGION" "$AWS_REGION"

read -p "ECS Cluster Name (default: projet-cloud-cluster): " ECS_CLUSTER
ECS_CLUSTER=${ECS_CLUSTER:-projet-cloud-cluster}
set_variable "ECS_CLUSTER" "$ECS_CLUSTER"

read -p "ECS Backend Service Name (default: projet-cloud-backend-service): " ECS_BACKEND_SERVICE
ECS_BACKEND_SERVICE=${ECS_BACKEND_SERVICE:-projet-cloud-backend-service}
set_variable "ECS_BACKEND_SERVICE" "$ECS_BACKEND_SERVICE"

read -p "ECS Frontend Service Name (default: projet-cloud-frontend-service): " ECS_FRONTEND_SERVICE
ECS_FRONTEND_SERVICE=${ECS_FRONTEND_SERVICE:-projet-cloud-frontend-service}
set_variable "ECS_FRONTEND_SERVICE" "$ECS_FRONTEND_SERVICE"

# Application Variables
read -p "Admin Emails (default: sorayapitroipa9@gmail.com): " APPVAR_ADMIN_EMAILS
APPVAR_ADMIN_EMAILS=${APPVAR_ADMIN_EMAILS:-sorayapitroipa9@gmail.com}
set_variable "APPVAR_ADMIN_EMAILS" "$APPVAR_ADMIN_EMAILS"

read -p "Google Client ID (for OAuth): " APPVAR_GOOGLE_CLIENT_ID
if [ -n "$APPVAR_GOOGLE_CLIENT_ID" ]; then
    set_variable "APPVAR_GOOGLE_CLIENT_ID" "$APPVAR_GOOGLE_CLIENT_ID"
else
    echo -e "${YELLOW}⚠ Skipped: APPVAR_GOOGLE_CLIENT_ID${NC}"
fi

read -p "Model S3 Bucket (optional, press Enter to skip): " APPVAR_MODEL_S3_BUCKET
if [ -n "$APPVAR_MODEL_S3_BUCKET" ]; then
    set_variable "APPVAR_MODEL_S3_BUCKET" "$APPVAR_MODEL_S3_BUCKET"
fi

read -p "Model S3 Key (optional, press Enter to skip): " APPVAR_MODEL_S3_KEY
if [ -n "$APPVAR_MODEL_S3_KEY" ]; then
    set_variable "APPVAR_MODEL_S3_KEY" "$APPVAR_MODEL_S3_KEY"
fi

echo ""
echo -e "${BLUE}=== GITHUB SECRETS ===${NC}"
echo "These are sensitive values - store them securely!"
echo ""

# AWS Secrets
read -p "AWS_ROLE_TO_ASSUME (OIDC role ARN): " AWS_ROLE_TO_ASSUME
if [ -n "$AWS_ROLE_TO_ASSUME" ]; then
    set_secret "AWS_ROLE_TO_ASSUME" "$AWS_ROLE_TO_ASSUME"
else
    echo -e "${YELLOW}⚠ Skipped: AWS_ROLE_TO_ASSUME${NC}"
fi

# DockerHub Secrets
read -p "DOCKERHUB_USERNAME: " DOCKERHUB_USERNAME
if [ -n "$DOCKERHUB_USERNAME" ]; then
    set_secret "DOCKERHUB_USERNAME" "$DOCKERHUB_USERNAME"
fi

read -sp "DOCKERHUB_TOKEN (password input, hidden): " DOCKERHUB_TOKEN
echo ""
if [ -n "$DOCKERHUB_TOKEN" ]; then
    set_secret "DOCKERHUB_TOKEN" "$DOCKERHUB_TOKEN"
fi

# Application Secrets
read -sp "APPVAR_JWT_SECRET (press Enter to generate): " APPVAR_JWT_SECRET
echo ""
if [ -z "$APPVAR_JWT_SECRET" ]; then
    APPVAR_JWT_SECRET=$(openssl rand -base64 32)
    echo -e "${YELLOW}Generated JWT Secret: $APPVAR_JWT_SECRET${NC}"
fi
set_secret "APPVAR_JWT_SECRET" "$APPVAR_JWT_SECRET"

read -p "APPVAR_DATABASE_URL (PostgreSQL connection string): " APPVAR_DATABASE_URL
if [ -n "$APPVAR_DATABASE_URL" ]; then
    set_secret "APPVAR_DATABASE_URL" "$APPVAR_DATABASE_URL"
else
    echo -e "${YELLOW}⚠ Skipped: APPVAR_DATABASE_URL (required for deployment)${NC}"
fi

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}Configuration completed!${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify all variables and secrets are set in GitHub:"
echo "   https://github.com/$REPO/settings/variables/actions"
echo "   https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "2. Create AWS infrastructure (choose one):"
echo "   a) Manual via AWS Console (see docs/AWS_DEPLOYMENT_GUIDE.md)"
echo "   b) Automated via CloudFormation:"
echo "      aws cloudformation create-stack --stack-name cequality-infra \\"
echo "        --template-body file://infra/cloudformation-template.yaml \\"
echo "        --parameters ParameterKey=DBMasterPassword,ParameterValue=YOUR_PASSWORD \\"
echo "        --region $AWS_REGION"
echo ""
echo "3. Push to main branch to trigger CI/CD:"
echo "   git push origin main"
echo ""
echo "4. Manually trigger deployment workflow:"
echo "   gh workflow run deploy-ecs.yml -f services=both"
echo ""
