#!/bin/bash

# Setup Terraform Backend (S3 + DynamoDB)
# This script creates the necessary AWS resources for Terraform remote state

set -e

# Configuration
AWS_REGION="${AWS_REGION:-ap-south-1}"
S3_BUCKET="${S3_BUCKET:-capstone-terraform-state-bucket}"
DYNAMODB_TABLE="${DYNAMODB_TABLE:-capstone-terraform-locks}"

echo "========================================="
echo "Setting up Terraform Backend"
echo "========================================="
echo "Region: $AWS_REGION"
echo "S3 Bucket: $S3_BUCKET"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo "========================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

echo "AWS credentials verified ✓"

# Create S3 bucket if it doesn't exist
echo ""
echo "Checking S3 bucket..."
if aws s3 ls "s3://${S3_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket: ${S3_BUCKET}"
    aws s3 mb "s3://${S3_BUCKET}" --region "${AWS_REGION}"
    
    echo "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "${S3_BUCKET}" \
        --versioning-configuration Status=Enabled
    
    echo "Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "${S3_BUCKET}" \
        --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    
    echo "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket "${S3_BUCKET}" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    echo "S3 bucket created and configured ✓"
else
    echo "S3 bucket already exists ✓"
fi

# Create DynamoDB table if it doesn't exist
echo ""
echo "Checking DynamoDB table..."
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" 2>&1 | grep -q 'ResourceNotFoundException'; then
    echo "Creating DynamoDB table: ${DYNAMODB_TABLE}"
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "${AWS_REGION}"
    
    echo "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}"
    
    echo "DynamoDB table created ✓"
else
    echo "DynamoDB table already exists ✓"
fi

echo ""
echo "========================================="
echo "Terraform backend setup complete! ✓"
echo "========================================="
echo ""
echo "You can now run:"
echo "  cd infra"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""

