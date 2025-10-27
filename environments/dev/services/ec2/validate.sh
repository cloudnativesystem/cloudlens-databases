#!/bin/bash
# validate.sh
# Pre-deployment validation script for EC2 Bastion Terraform configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

echo "=========================================="
echo "EC2 Bastion Deployment Validation Script"
echo "=========================================="
echo ""

# Function to print success
print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

# Function to print error
print_error() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check 1: Terraform installed
echo "Checking prerequisites..."
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_success "Terraform installed (version $TERRAFORM_VERSION)"
else
    print_error "Terraform is not installed"
fi

# Check 2: AWS CLI installed
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version | cut -d' ' -f1)
    print_success "AWS CLI installed ($AWS_VERSION)"
else
    print_error "AWS CLI is not installed"
fi

# Check 3: jq installed (for JSON parsing)
if command -v jq &> /dev/null; then
    print_success "jq installed"
else
    print_warning "jq is not installed (recommended for credential retrieval)"
fi

echo ""
echo "Checking AWS credentials..."

# Check 4: AWS credentials configured
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    print_success "AWS credentials configured"
    echo "  Account: $ACCOUNT_ID"
    echo "  Identity: $USER_ARN"
else
    print_error "AWS credentials not configured or invalid"
fi

# Check 5: AWS region configured
AWS_REGION=$(aws configure get region)
if [ -n "$AWS_REGION" ]; then
    print_success "AWS region configured: $AWS_REGION"
else
    print_warning "AWS region not configured (will use default)"
fi

echo ""
echo "Checking Terraform configuration..."

# Check 6: Terraform files exist
if [ -f "service_ec2_main.tf" ]; then
    print_success "service_ec2_main.tf exists"
else
    print_error "service_ec2_main.tf not found"
fi

if [ -f "service_ec2_variables.tf" ]; then
    print_success "service_ec2_variables.tf exists"
else
    print_error "service_ec2_variables.tf not found"
fi

if [ -f "service_ec2.tfvars" ]; then
    print_success "service_ec2.tfvars exists"
else
    print_error "service_ec2.tfvars not found"
fi

# Check 7: Module exists
if [ -d "../../../../modules/ec2" ]; then
    print_success "EC2 module directory exists"
else
    print_error "EC2 module directory not found"
fi

echo ""
echo "Validating configuration values..."

# Check 8: VPC ID format
VPC_ID=$(grep -E "^vpc_id\s*=" service_ec2.tfvars | cut -d'"' -f2)
if [[ $VPC_ID =~ ^vpc-[a-f0-9]{8,17}$ ]]; then
    print_success "VPC ID format is valid: $VPC_ID"
    
    # Check if VPC exists
    if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" &> /dev/null; then
        print_success "VPC exists in AWS"
    else
        print_error "VPC not found in AWS: $VPC_ID"
    fi
elif [[ $VPC_ID == "vpc-xxxxxxxxxxxxxxxxx" ]]; then
    print_error "VPC ID is still a placeholder - update service_ec2.tfvars"
else
    print_error "VPC ID format is invalid: $VPC_ID"
fi

# Check 9: Subnet ID
SUBNET_ID=$(grep -E "^subnet_id\s*=" service_ec2.tfvars | cut -d'"' -f2)
if [[ $SUBNET_ID =~ ^subnet-[a-f0-9]{8,17}$ ]]; then
    print_success "Subnet ID format is valid: $SUBNET_ID"
    
    # Check if subnet exists
    if aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" &> /dev/null; then
        print_success "Subnet exists in AWS"
        
        # Check if subnet is in the VPC
        SUBNET_VPC=$(aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --query 'Subnets[0].VpcId' --output text)
        if [ "$SUBNET_VPC" = "$VPC_ID" ]; then
            print_success "Subnet is in the correct VPC"
        else
            print_error "Subnet is not in the specified VPC (found in $SUBNET_VPC)"
        fi
    else
        print_error "Subnet not found in AWS: $SUBNET_ID"
    fi
elif [[ $SUBNET_ID == "subnet-xxxxxxxxxxxxxxxxx" ]]; then
    print_error "Subnet ID is still a placeholder - update service_ec2.tfvars"
else
    print_error "Subnet ID format is invalid: $SUBNET_ID"
fi

# Check 10: KMS Key ARN
KMS_KEY_ARN=$(grep -E "^kms_key_id\s*=" service_ec2.tfvars | cut -d'"' -f2)
if [[ $KMS_KEY_ARN =~ ^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$ ]]; then
    print_success "KMS key ARN format is valid"
    
    # Check if KMS key exists and is accessible
    if aws kms describe-key --key-id "$KMS_KEY_ARN" &> /dev/null; then
        print_success "KMS key exists and is accessible"
        
        # Check if key is enabled
        KEY_STATE=$(aws kms describe-key --key-id "$KMS_KEY_ARN" --query 'KeyMetadata.KeyState' --output text)
        if [ "$KEY_STATE" = "Enabled" ]; then
            print_success "KMS key is enabled"
        else
            print_error "KMS key is not enabled (state: $KEY_STATE)"
        fi
    else
        print_error "KMS key not found or not accessible: $KMS_KEY_ARN"
    fi
elif [[ $KMS_KEY_ARN == *"123456789012"* ]]; then
    print_error "KMS key ARN is still a placeholder - update service_ec2.tfvars"
else
    print_error "KMS key ARN format is invalid: $KMS_KEY_ARN"
fi

# Check 11: Instance type
INSTANCE_TYPE=$(grep -E "^instance_type\s*=" service_ec2.tfvars | cut -d'"' -f2)
if [ -n "$INSTANCE_TYPE" ]; then
    print_success "Instance type configured: $INSTANCE_TYPE"
else
    print_warning "Instance type not explicitly set (will use default)"
fi

# Check 12: Root volume encryption
ROOT_ENCRYPTED=$(grep -E "^root_volume_encrypted\s*=" service_ec2.tfvars | awk '{print $3}')
if [ "$ROOT_ENCRYPTED" = "true" ]; then
    print_success "Root volume encryption enabled"
else
    print_warning "Root volume encryption not enabled (recommended for production)"
fi

# Check 13: IMDSv2 requirement
REQUIRE_IMDSV2=$(grep -E "^require_imdsv2\s*=" service_ec2.tfvars | awk '{print $3}')
if [ "$REQUIRE_IMDSV2" = "true" ]; then
    print_success "IMDSv2 required (enhanced security)"
else
    print_warning "IMDSv2 not required (recommended for security)"
fi

# Check 14: SSH key creation
CREATE_SSH_KEY=$(grep -E "^create_ssh_key\s*=" service_ec2.tfvars | awk '{print $3}')
if [ "$CREATE_SSH_KEY" = "true" ]; then
    print_success "SSH key will be auto-generated"
else
    print_warning "Using existing SSH key pair"
fi

# Check 15: Security group or CIDR configuration
SG_COUNT=$(grep -A 10 "^allowed_security_group_ids\s*=" service_ec2.tfvars | grep -c "sg-" || true)
CIDR_COUNT=$(grep -A 10 "^allowed_cidr_blocks\s*=" service_ec2.tfvars | grep -c "/" || true)

if [ "$SG_COUNT" -gt 0 ] || [ "$CIDR_COUNT" -gt 0 ]; then
    print_success "SSH access control configured ($SG_COUNT security groups, $CIDR_COUNT CIDR blocks)"
else
    print_warning "No SSH access control configured (security group or CIDR blocks recommended)"
fi

echo ""
echo "Running Terraform validation..."

# Check 16: Terraform init
if [ -d ".terraform" ]; then
    print_success "Terraform initialized"
else
    print_warning "Terraform not initialized - run 'terraform init'"
fi

# Check 17: Terraform validate
if terraform validate &> /dev/null; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed - run 'terraform validate' for details"
fi

# Check 18: Terraform fmt
if terraform fmt -check &> /dev/null; then
    print_success "Terraform files are properly formatted"
else
    print_warning "Terraform files need formatting - run 'terraform fmt'"
fi

echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "${GREEN}Checks passed: $CHECKS_PASSED${NC}"
echo -e "${RED}Checks failed: $CHECKS_FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review the configuration: terraform plan -var-file=\"service_ec2.tfvars\""
    echo "2. Deploy the infrastructure: terraform apply -var-file=\"service_ec2.tfvars\""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above before deploying.${NC}"
    exit 1
fi

