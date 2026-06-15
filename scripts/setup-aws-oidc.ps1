# setup-aws-oidc.ps1 - Configure AWS IAM for GitHub OIDC (PowerShell Version)

param(
    [string]$Region = "eu-west-1",
    [string]$GitHubOrg = $(Read-Host "Enter GitHub Organization (e.g., your-username or org-name)")
)

Write-Host "🔐 Setting up AWS IAM for GitHub OIDC" -ForegroundColor Cyan
Write-Host "   Region: $Region" -ForegroundColor Yellow
Write-Host "   GitHub Org: $GitHubOrg" -ForegroundColor Yellow
Write-Host ""

# Step 1: Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Green
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Install from: https://aws.amazon.com/cli/" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 1: Create OIDC Provider
Write-Host "📌 Step 1: Creating OIDC Provider (if not exists)" -ForegroundColor Cyan

try {
    $providers = aws iam list-open-id-connect-providers --region $Region | ConvertFrom-Json
    $existing = $providers.OpenIDConnectProviderList | Where-Object { $_ -like "*token.actions.githubusercontent.com*" }
    
    if ($existing) {
        $providerArn = $existing.Arn
        Write-Host "   ✅ Already exists: $providerArn" -ForegroundColor Green
    } else {
        Write-Host "   Creating new OIDC provider..." -ForegroundColor Yellow
        $result = aws iam create-open-id-connect-provider `
            --url "https://token.actions.githubusercontent.com" `
            --client-id-list "sts.amazonaws.com" `
            --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" `
            --region $Region | ConvertFrom-Json
        
        $providerArn = $result.OpenIDConnectProviderArn
        Write-Host "   ✅ Created: $providerArn" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error creating OIDC provider: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Create IAM Role
Write-Host "📌 Step 2: Creating IAM Role for GitHub Actions" -ForegroundColor Cyan

$roleName = "github-actions-ecr-ecs"

try {
    $existingRole = aws iam get-role --role-name $roleName 2>$null
    if ($existingRole) {
        $roleArn = ($existingRole | ConvertFrom-Json).Role.Arn
        Write-Host "   ✅ Role already exists: $roleName" -ForegroundColor Green
        Write-Host "   ARN: $roleArn" -ForegroundColor Green
    } else {
        Write-Host "   Creating new role..." -ForegroundColor Yellow
        
        # Create trust policy
        $trustPolicy = @{
            Version = "2012-10-17"
            Statement = @(
                @{
                    Effect = "Allow"
                    Principal = @{
                        Federated = $providerArn
                    }
                    Action = "sts:AssumeRoleWithWebIdentity"
                    Condition = @{
                        StringEquals = @{
                            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                        }
                        StringLike = @{
                            "token.actions.githubusercontent.com:sub" = "repo:$GitHubOrg/*:ref:refs/heads/main"
                        }
                    }
                }
            )
        } | ConvertTo-Json -Depth 10
        
        # Save to temp file
        $tempFile = [System.IO.Path]::GetTempFileName()
        $trustPolicy | Out-File -FilePath $tempFile -Encoding UTF8
        
        $result = aws iam create-role `
            --role-name $roleName `
            --assume-role-policy-document file://$tempFile | ConvertFrom-Json
        
        $roleArn = $result.Role.Arn
        Write-Host "   ✅ Created: $roleArn" -ForegroundColor Green
        
        # Cleanup
        Remove-Item -Path $tempFile -Force
    }
} catch {
    Write-Host "❌ Error creating role: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Attach Policies
Write-Host "📌 Step 3: Attaching policies to role" -ForegroundColor Cyan

try {
    # Create policy document
    $policyDocument = @{
        Version = "2012-10-17"
        Statement = @(
            @{
                Effect = "Allow"
                Action = @(
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
                )
                Resource = "*"
            },
            @{
                Effect = "Allow"
                Action = @(
                    "ecs:DescribeServices",
                    "ecs:DescribeTaskDefinition",
                    "ecs:DescribeContainerInstances",
                    "ecs:UpdateService",
                    "ecs:RegisterTaskDefinition",
                    "ecs:ListServices"
                )
                Resource = "*"
            },
            @{
                Effect = "Allow"
                Action = @(
                    "iam:PassRole"
                )
                Resource = @(
                    "arn:aws:iam::*:role/ecsTaskExecutionRole",
                    "arn:aws:iam::*:role/ecsTaskRole"
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    # Save to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    $policyDocument | Out-File -FilePath $tempFile -Encoding UTF8
    
    # Check if policy already exists
    try {
        $existingPolicy = aws iam get-role-policy --role-name $roleName --policy-name "github-ecr-ecs-policy" 2>$null
        Write-Host "   ✅ Policy already attached" -ForegroundColor Green
    } catch {
        aws iam put-role-policy `
            --role-name $roleName `
            --policy-name "github-ecr-ecs-policy" `
            --policy-document file://$tempFile | Out-Null
        
        Write-Host "   ✅ Attached ECR/ECS policy" -ForegroundColor Green
    }
    
    # Cleanup
    Remove-Item -Path $tempFile -Force
} catch {
    Write-Host "❌ Error attaching policy: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✨ Configuration Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Configuration Summary:" -ForegroundColor Cyan
Write-Host "   Role ARN: $roleArn" -ForegroundColor Yellow
Write-Host "   Role Name: $roleName" -ForegroundColor Yellow
Write-Host ""
Write-Host "📝 Add to GitHub Secrets:" -ForegroundColor Cyan
Write-Host "   gh secret set AWS_ROLE_TO_ASSUME --body '$roleArn'" -ForegroundColor Yellow
Write-Host ""
Write-Host "   or in GitHub UI:" -ForegroundColor Cyan
Write-Host "   Settings > Secrets and variables > Actions > New repository secret" -ForegroundColor Gray
Write-Host "   Name: AWS_ROLE_TO_ASSUME" -ForegroundColor Gray
Write-Host "   Value: $roleArn" -ForegroundColor Gray
Write-Host ""
