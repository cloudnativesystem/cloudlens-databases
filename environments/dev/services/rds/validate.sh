#!/bin/bash
# validate.sh
# Pre-deployment validation script for RDS Terraform configuration

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
echo "RDS Deployment Validation Script"
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
if [ -f "service_rds_main.tf" ]; then
    print_success "service_rds_main.tf exists"
else
    print_error "service_rds_main.tf not found"
fi

if [ -f "service_rds_variables.tf" ]; then
    print_success "service_rds_variables.tf exists"
else
    print_error "service_rds_variables.tf not found"
fi

if [ -f "service_rds.tfvars" ]; then
    print_success "service_rds.tfvars exists"
else
    print_error "service_rds.tfvars not found"
fi

# Check 7: Module exists
if [ -d "../../../../modules/rds" ]; then
    print_success "RDS module directory exists"
else
    print_error "RDS module directory not found"
fi

echo ""
echo "Validating configuration values..."

# Check 8: VPC ID format
VPC_ID=$(grep -E "^vpc_id\s*=" service_rds.tfvars | cut -d'"' -f2)
if [[ $VPC_ID =~ ^vpc-[a-f0-9]{8,17}$ ]]; then
    print_success "VPC ID format is valid: $VPC_ID"
    
    # Check if VPC exists
    if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" &> /dev/null; then
        print_success "VPC exists in AWS"
    else
        print_error "VPC not found in AWS: $VPC_ID"
    fi
elif [[ $VPC_ID == "vpc-xxxxxxxxxxxxxxxxx" ]]; then
    print_error "VPC ID is still a placeholder - update service_rds.tfvars"
else
    print_error "VPC ID format is invalid: $VPC_ID"
fi

# Check 9: Subnet IDs
SUBNET_COUNT=$(grep -A 10 "^subnet_ids\s*=" service_rds.tfvars | grep -c "subnet-" || true)
if [ "$SUBNET_COUNT" -ge 2 ]; then
    print_success "At least 2 subnet IDs configured"
    
    # Extract subnet IDs and check if they're placeholders
    SUBNETS=$(grep -A 10 "^subnet_ids\s*=" service_rds.tfvars | grep "subnet-" | cut -d'"' -f2)
    PLACEHOLDER_COUNT=$(echo "$SUBNETS" | grep -c "subnet-xxxxx" || true)
    
    if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
        print_error "Subnet IDs contain placeholders - update service_rds.tfvars"
    else
        # Check if subnets exist and are in different AZs
        AZS=()
        ALL_SUBNETS_VALID=true
        while IFS= read -r subnet; do
            if aws ec2 describe-subnets --subnet-ids "$subnet" &> /dev/null; then
                AZ=$(aws ec2 describe-subnets --subnet-ids "$subnet" --query 'Subnets[0].AvailabilityZone' --output text)
                AZS+=("$AZ")
            else
                print_error "Subnet not found: $subnet"
                ALL_SUBNETS_VALID=false
            fi
        done <<< "$SUBNETS"
        
        if [ "$ALL_SUBNETS_VALID" = true ]; then
            print_success "All subnets exist in AWS"
            
            # Check if subnets are in different AZs
            UNIQUE_AZS=$(printf '%s\n' "${AZS[@]}" | sort -u | wc -l)
            if [ "$UNIQUE_AZS" -ge 2 ]; then
                print_success "Subnets are in different availability zones"
            else
                print_error "Subnets must be in at least 2 different availability zones"
            fi
        fi
    fi
else
    print_error "Less than 2 subnet IDs configured (found: $SUBNET_COUNT)"
fi

# Check 10: Instance class
INSTANCE_CLASS=$(grep -E "^instance_class\s*=" service_rds.tfvars | cut -d'"' -f2)
if [ -n "$INSTANCE_CLASS" ]; then
    print_success "Instance class configured: $INSTANCE_CLASS"
else
    print_warning "Instance class not explicitly set (will use default)"
fi

# Check 11: Storage encryption
STORAGE_ENCRYPTED=$(grep -E "^storage_encrypted\s*=" service_rds.tfvars | awk '{print $3}')
if [ "$STORAGE_ENCRYPTED" = "true" ]; then
    print_success "Storage encryption enabled"
else
    print_warning "Storage encryption not enabled (recommended for production)"
fi

# Check 12: Backup retention
BACKUP_RETENTION=$(grep -E "^backup_retention_period\s*=" service_rds.tfvars | awk '{print $3}')
if [ -n "$BACKUP_RETENTION" ] && [ "$BACKUP_RETENTION" -gt 0 ]; then
    print_success "Backup retention configured: $BACKUP_RETENTION days"
else
    print_warning "Backup retention not configured or disabled"
fi

echo ""
echo "Running Terraform validation..."

# Check 13: Terraform init
if [ -d ".terraform" ]; then
    print_success "Terraform initialized"
else
    print_warning "Terraform not initialized - run 'terraform init'"
fi

# Check 14: Terraform validate
if terraform validate &> /dev/null; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed - run 'terraform validate' for details"
fi

# Check 15: Terraform fmt
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
    echo "1. Review the configuration: terraform plan -var-file=\"service_rds.tfvars\""
    echo "2. Deploy the infrastructure: terraform apply -var-file=\"service_rds.tfvars\""
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above before deploying.${NC}"
    exit 1
fi

