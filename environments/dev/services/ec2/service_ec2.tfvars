# service_ec2.tfvars
# Configuration for EC2 Bastion Host - Development Environment

# ===========================
# Instance Identification
# ===========================

name = "cloudlens-bastion-dev"

# ===========================
# Network Configuration
# ===========================

# IMPORTANT: Replace with your actual VPC ID
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# IMPORTANT: Replace with your actual private subnet ID
# This should be a private subnet in the same VPC as the RDS instance
subnet_id = "subnet-xxxxxxxxxxxxxxxxx"

# ===========================
# KMS Encryption
# ===========================

# IMPORTANT: Replace with your actual KMS key ARN
# This KMS key will be used for:
# - EBS volume encryption
# - SSM Parameter Store encryption (for private key storage)
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# ===========================
# Instance Configuration
# ===========================

instance_type = "t2.small"  # Small instance for dev (suitable for bastion host)
ami_id        = null        # Use latest Amazon Linux 2023 AMI

# ===========================
# Storage Configuration
# ===========================

root_volume_type                  = "gp3"  # General Purpose SSD (gp3)
root_volume_size                  = 100    # 100 GB as specified
root_volume_encrypted             = true   # Enable encryption at rest
root_volume_delete_on_termination = true   # Delete volume on instance termination (dev environment)

# ===========================
# Security Group Configuration
# ===========================

create_security_group = true  # Create a new security group for the bastion host

# IMPORTANT: Replace with security group IDs that need SSH access to the bastion
# Example: Security groups for developers, CI/CD systems, etc.
allowed_security_group_ids = [
  # "sg-xxxxxxxxxxxxxxxxx"  # Example: Developer VPN security group
  # "sg-yyyyyyyyyyyyyyyyy"  # Example: CI/CD security group
]

# Alternative: Allow SSH from specific CIDR blocks
# WARNING: Be restrictive with CIDR blocks for security
allowed_cidr_blocks = [
  # "10.0.0.0/8"  # Example: Internal network only
]

# ===========================
# Elastic IP Configuration
# ===========================

# Do not allocate EIP for dev environment (private subnet deployment)
allocate_eip = false

# ===========================
# SSH Key Configuration
# ===========================

create_ssh_key     = true   # Generate new SSH key pair
ssh_key_algorithm  = "RSA"  # Use RSA algorithm
ssh_key_rsa_bits   = 4096   # 4096-bit RSA key for enhanced security
ssm_parameter_name = null   # Use default: /cloudlens-bastion-dev/ssh-private-key

# If you want to use an existing key pair instead:
# create_ssh_key = false
# existing_key_pair_name = "my-existing-key"

# ===========================
# IAM Configuration
# ===========================

# Additional IAM policies to attach to the bastion instance role
# Example: Add read-only access to Secrets Manager for RDS credentials
additional_iam_policy_arns = [
  # "arn:aws:iam::aws:policy/SecretsManagerReadWrite"  # For RDS credential access
]

# ===========================
# Monitoring and Logging
# ===========================

enable_detailed_monitoring = true  # Enable detailed CloudWatch monitoring (1-minute intervals)
enable_cloudwatch_agent    = true  # Install and configure CloudWatch Agent for logs and metrics

# ===========================
# Security Configuration
# ===========================

require_imdsv2 = true  # Require IMDSv2 for enhanced security (recommended)

# ===========================
# User Data Configuration
# ===========================

user_data = null  # Use default user_data.sh script from module

# ===========================
# Source/Destination Check
# ===========================

source_dest_check = true  # Enable source/destination checking (disable only for NAT instances)

# ===========================
# Environment Tags
# ===========================

environment = "dev"
project     = "cloudlens"
owner       = "cloudlens"

additional_tags = {
  # Add any additional custom tags here
  # CostCenter = "engineering"
  # Team       = "platform"
}
