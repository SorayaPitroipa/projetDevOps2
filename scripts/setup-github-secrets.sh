#!/bin/bash
# setup-github-secrets.sh - Configure GitHub Secrets for CI/CD Pipeline

set -e

REPO="${1:?Usage: ./setup-github-secrets.sh <owner/repo>}"

echo "🔐 Setting up GitHub Secrets for CI/CD Pipeline"
echo "   Repository: $REPO"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install from: https://cli.github.com"
    exit 1
fi

# Authenticate with GitHub
echo "🔑 Checking GitHub authentication..."
gh auth status --hostname github.com

echo ""
echo "📋 Choose what to configure:"
echo ""
echo "1️⃣  AWS (ECR + ECS Deployment)"
echo "2️⃣  Security Scanning (Snyk)"
echo "3️⃣  DockerHub (optional image registry)"
echo "4️⃣  All of the above"
echo "5️⃣  Just view current secrets"
echo ""
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "🔄 AWS Configuration"
        echo "First, create IAM role for GitHub OIDC (if not done already):"
        echo ""
        echo "1. Create OIDC provider (one-time):"
        echo "   aws iam create-open-id-connect-provider \\"
        echo "     --url https://token.actions.githubusercontent.com \\"
        echo "     --client-id-list sts.amazonaws.com"
        echo ""
        echo "2. Create IAM role with policies (see infra/aws/AUTOMATION.md)"
        echo ""
        
        read -p "Enter AWS Role ARN (e.g., arn:aws:iam::123456789:role/github-actions-role): " AWS_ROLE
        read -p "Enter AWS Region (default: eu-west-1): " AWS_REGION
        AWS_REGION=${AWS_REGION:-eu-west-1}
        
        gh secret set AWS_ROLE_TO_ASSUME --repo "$REPO" --body "$AWS_ROLE"
        gh variable set AWS_REGION --repo "$REPO" --body "$AWS_REGION"
        
        echo "✅ AWS secrets configured"
        ;;
    2)
        echo ""
        echo "🔍 Snyk Configuration"
        read -p "Enter Snyk API Token: " -s SNYK_TOKEN
        echo ""
        
        gh secret set SNYK_TOKEN --repo "$REPO" --body "$SNYK_TOKEN"
        echo "✅ Snyk token configured"
        ;;
    3)
        echo ""
        echo "🐳 DockerHub Configuration"
        read -p "Enter DockerHub Username: " DH_USERNAME
        read -p "Enter DockerHub Token: " -s DH_TOKEN
        echo ""
        
        gh secret set DOCKERHUB_USERNAME --repo "$REPO" --body "$DH_USERNAME"
        gh secret set DOCKERHUB_TOKEN --repo "$REPO" --body "$DH_TOKEN"
        echo "✅ DockerHub credentials configured"
        ;;
    4)
        echo ""
        echo "🔄 AWS Configuration"
        read -p "Enter AWS Role ARN: " AWS_ROLE
        read -p "Enter AWS Region (default: eu-west-1): " AWS_REGION
        AWS_REGION=${AWS_REGION:-eu-west-1}
        
        gh secret set AWS_ROLE_TO_ASSUME --repo "$REPO" --body "$AWS_ROLE"
        gh variable set AWS_REGION --repo "$REPO" --body "$AWS_REGION"
        echo "✅ AWS secrets configured"
        
        echo ""
        echo "🔍 Snyk Configuration"
        read -p "Enter Snyk API Token: " -s SNYK_TOKEN
        echo ""
        gh secret set SNYK_TOKEN --repo "$REPO" --body "$SNYK_TOKEN"
        echo "✅ Snyk token configured"
        
        echo ""
        echo "🐳 DockerHub Configuration"
        read -p "Enter DockerHub Username: " DH_USERNAME
        read -p "Enter DockerHub Token: " -s DH_TOKEN
        echo ""
        gh secret set DOCKERHUB_USERNAME --repo "$REPO" --body "$DH_USERNAME"
        gh secret set DOCKERHUB_TOKEN --repo "$REPO" --body "$DH_TOKEN"
        echo "✅ DockerHub credentials configured"
        ;;
    5)
        echo ""
        echo "📋 Current Secrets & Variables:"
        echo ""
        gh secret list --repo "$REPO" || echo "(No secrets configured)"
        echo ""
        echo "📋 Current Variables:"
        gh variable list --repo "$REPO" || echo "(No variables configured)"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✨ Configuration complete!"
echo ""
echo "Next steps:"
echo "1. Configure ECS resources (update GitHub variables):"
echo "   gh variable set ECS_CLUSTER --repo $REPO --body 'your-cluster'"
echo "   gh variable set ECS_BACKEND_SERVICE --repo $REPO --body 'your-service'"
echo "   gh variable set ECS_FRONTEND_SERVICE --repo $REPO --body 'your-service'"
echo ""
echo "2. View CI/CD Guide: docs/CI_CD_GUIDE.md"
echo "3. Push code to main branch to trigger pipeline"
echo ""

