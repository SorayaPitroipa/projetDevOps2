#!/bin/bash
# =============================================================================
# AWS Deployment Configuration Helper (FIXED & IMPROVED)
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}AWS Deployment Configuration Helper (Improved)${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) not installed${NC}"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Not authenticated with GitHub. Run: gh auth login${NC}"
    exit 1
fi

# FIXED: correct repo detection
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

echo -e "${GREEN}Repository: $REPO${NC}"
echo ""

# ----------------------------
# FUNCTIONS
# ----------------------------

set_variable() {
    local name=$1
    local value=$2

    echo -e "${YELLOW}Setting variable: $name${NC}"

    gh variable set "$name" --body "$value" --repo "$REPO" >/dev/null 2>&1 || {
        echo -e "${RED}Failed variable: $name${NC}"
        return 1
    }

    echo -e "${GREEN}✓ $name${NC}"
}

set_secret() {
    local name=$1
    local value=$2

    echo -e "${YELLOW}Setting secret: $name${NC}"

    gh secret set "$name" --body "$value" --repo "$REPO" >/dev/null 2>&1 || {
        echo -e "${RED}Failed secret: $name${NC}"
        return 1
    }

    echo -e "${GREEN}✓ $name${NC}"
}

# ----------------------------
# VARIABLES
# ----------------------------

echo -e "${BLUE}=== GITHUB VARIABLES ===${NC}"

AWS_REGION=${AWS_REGION:-eu-west-1}
set_variable "AWS_REGION" "$AWS_REGION"

ECS_CLUSTER=${ECS_CLUSTER:-projet-cloud-cluster}
set_variable "ECS_CLUSTER" "$ECS_CLUSTER"

ECS_BACKEND_SERVICE=${ECS_BACKEND_SERVICE:-projet-cloud-backend-service}
set_variable "ECS_BACKEND_SERVICE" "$ECS_BACKEND_SERVICE"

ECS_FRONTEND_SERVICE=${ECS_FRONTEND_SERVICE:-projet-cloud-frontend-service}
set_variable "ECS_FRONTEND_SERVICE" "$ECS_FRONTEND_SERVICE"

APPVAR_ADMIN_EMAILS=${APPVAR_ADMIN_EMAILS:-"sorayapitroipa9@gmail.com"}
set_variable "APPVAR_ADMIN_EMAILS" "$APPVAR_ADMIN_EMAILS"

# Optional variables
read -p "Google Client ID (optional): " GOOGLE_CLIENT_ID
[[ -n "$GOOGLE_CLIENT_ID" ]] && set_variable "APPVAR_GOOGLE_CLIENT_ID" "$GOOGLE_CLIENT_ID"

read -p "Model S3 Bucket (optional): " S3_BUCKET
[[ -n "$S3_BUCKET" ]] && set_variable "APPVAR_MODEL_S3_BUCKET" "$S3_BUCKET"

read -p "Model S3 Key (optional): " S3_KEY
[[ -n "$S3_KEY" ]] && set_variable "APPVAR_MODEL_S3_KEY" "$S3_KEY"

# ----------------------------
# SECRETS
# ----------------------------

echo ""
echo -e "${BLUE}=== GITHUB SECRETS ===${NC}"

read -p "AWS_ROLE_TO_ASSUME (OIDC ARN): " AWS_ROLE
[[ -n "$AWS_ROLE" ]] && set_secret "AWS_ROLE_TO_ASSUME" "$AWS_ROLE"

read -p "AWS_ACCOUNT_ID (recommended): " AWS_ACCOUNT
[[ -n "$AWS_ACCOUNT" ]] && set_secret "AWS_ACCOUNT_ID" "$AWS_ACCOUNT"

read -p "DOCKERHUB_USERNAME: " DOCKER_USER
[[ -n "$DOCKER_USER" ]] && set_secret "DOCKERHUB_USERNAME" "$DOCKER_USER"

read -sp "DOCKERHUB_TOKEN: " DOCKER_TOKEN
echo ""
[[ -n "$DOCKER_TOKEN" ]] && set_secret "DOCKERHUB_TOKEN" "$DOCKER_TOKEN"

# ----------------------------
# JWT (FIXED SAFE HANDLING)
# ----------------------------

echo ""
echo "Generating JWT secret..."

JWT_SECRET=$(openssl rand -base64 32)

set_secret "APPVAR_JWT_SECRET" "$JWT_SECRET"

echo -e "${YELLOW}JWT secret generated and stored securely${NC}"

# ----------------------------
# DATABASE URL
# ----------------------------

read -p "APPVAR_DATABASE_URL (or press Enter to auto-fetch later): " DB_URL
[[ -n "$DB_URL" ]] && set_secret "APPVAR_DATABASE_URL" "$DB_URL"

# ----------------------------
# SUMMARY
# ----------------------------

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}Configuration completed successfully!${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""

echo "Next steps:"
echo ""
echo "1. Verify GitHub settings:"
echo "   https://github.com/$REPO/settings/variables/actions"
echo "   https://github.com/$REPO/settings/secrets/actions"
echo ""

echo "2. Deploy infrastructure:"
echo "   aws cloudformation create-stack \\"
echo "     --stack-name cequality-infra \\"
echo "     --template-body file://infra/cloudformation-template.yaml \\"
echo "     --parameters ParameterKey=DBMasterPassword,ParameterValue=YOUR_PASSWORD \\"
echo "     --region $AWS_REGION"
echo ""

echo "3. Push code to trigger CI/CD:"
echo "   git push origin main"
echo ""

echo "4. Run deployment workflow:"
echo "   gh workflow run deploy-ecs.yml -f services=both"
echo ""

echo -e "${BLUE}Done.${NC}"