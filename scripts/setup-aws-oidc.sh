#!/bin/bash
# setup-aws-oidc.sh - Configure AWS IAM for GitHub OIDC

set -e

AWS_REGION="${1:-eu-west-1}"
GITHUB_ORG="${2:?Usage: ./setup-aws-oidc.sh [AWS_REGION] <GITHUB_ORG>}"

echo "🔐 Setting up AWS IAM for GitHub OIDC"
echo "   Region: $AWS_REGION"
echo "   GitHub Org: $GITHUB_ORG"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Install from: https://aws.amazon.com/cli/"
    exit 1
fi

# Step 1: Create OIDC Provider
echo "📌 Step 1: Creating OIDC Provider (if not exists)"
PROVIDER_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?Arn contains 'token.actions.githubusercontent.com'].Arn" --output text --region "$AWS_REGION" 2>/dev/null)

if [ -z "$PROVIDER_ARN" ]; then
    echo "   Creating new OIDC provider..."
    PROVIDER_ARN=$(aws iam create-open-id-connect-provider \
        --url "https://token.actions.githubusercontent.com" \
        --client-id-list "sts.amazonaws.com" \
        --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
        --region "$AWS_REGION" \
        --query 'OpenIDConnectProviderArn' \
        --output text)
    echo "   ✅ Created: $PROVIDER_ARN"
else
    echo "   ✅ Already exists: $PROVIDER_ARN"
fi

# Step 2: Create IAM Role
echo ""
echo "📌 Step 2: Creating IAM Role for GitHub Actions"

ROLE_NAME="github-actions-ecr-ecs"

# Check if role exists
if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
    echo "   ✅ Role already exists: $ROLE_NAME"
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
else
    echo "   Creating new role..."
    
    # Create trust policy
    TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$PROVIDER_ARN"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/*:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF
)

    ROLE_ARN=$(aws iam create-role \
        --role-name "$ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --query 'Role.Arn' \
        --output text)
    
    echo "   ✅ Created: $ROLE_ARN"
fi

# Step 3: Attach ECR & ECS policies
echo ""
echo "📌 Step 3: Attaching policies to role"

# Create custom policy for ECR & ECS
POLICY_DOCUMENT=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:UploadLayerPart",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeContainerInstances",
        "ecs:UpdateService",
        "ecs:RegisterTaskDefinition",
        "ecs:ListServices"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/ecsTaskExecutionRole",
        "arn:aws:iam::*:role/ecsTaskRole"
      ]
    }
  ]
}
EOF
)

# Check if inline policy exists
if ! aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "github-ecr-ecs-policy" &>/dev/null; then
    aws iam put-role-policy \
        --role-name "$ROLE_NAME" \
        --policy-name "github-ecr-ecs-policy" \
        --policy-document "$POLICY_DOCUMENT"
    echo "   ✅ Attached ECR/ECS policy"
else
    echo "   ✅ Policy already attached"
fi

# Step 4: Display configuration
echo ""
echo "✨ Configuration Complete!"
echo ""
echo "📋 Configuration Summary:"
echo "   Role ARN: $ROLE_ARN"
echo "   Role Name: $ROLE_NAME"
echo ""
echo "📝 Add to GitHub Secrets:"
echo "   gh secret set AWS_ROLE_TO_ASSUME --body '$ROLE_ARN'"
echo ""
echo "   or in GitHub UI:"
echo "   Settings > Secrets and variables > Actions > New repository secret"
echo "   Name: AWS_ROLE_TO_ASSUME"
echo "   Value: $ROLE_ARN"
echo ""
echo "🧪 Test the configuration:"
echo "   aws sts assume-role-with-web-identity \\"
echo "     --role-arn $ROLE_ARN \\"
echo "     --role-session-name github-actions \\"
echo "     --web-identity-token \$OIDC_TOKEN \\"
echo "     --duration-seconds 3600"
echo ""

