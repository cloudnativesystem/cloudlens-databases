# examples.tf
# Usage examples for the EC2 Bastion Host module
# These are examples only - do not apply directly

# ===========================
# Example 1: Basic Bastion Host
# ===========================
# Minimal configuration with auto-generated SSH key

module "basic_bastion" {
  source = "./modules/ec2"

  name       = "my-bastion"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  instance_type = "t2.micro"

  # Auto-generate SSH key
  create_ssh_key = true

  # Allow SSH from specific CIDR
  allowed_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "dev"
    Project     = "example"
  }
}

# ===========================
# Example 2: Production Bastion Host
# ===========================
# Production-ready configuration with enhanced security

module "production_bastion" {
  source = "./modules/ec2"

  name       = "prod-bastion"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Larger instance for production
  instance_type = "t3.small"

  # Storage configuration
  root_volume_type = "gp3"
  root_volume_size = 100

  # Auto-generate SSH key with ED25519 algorithm
  create_ssh_key    = true
  ssh_key_algorithm = "ED25519"

  # Restrict SSH access to specific security groups
  allowed_security_group_ids = [
    "sg-0123456789abcdef0",  # VPN security group
    "sg-0123456789abcdef1",  # Admin security group
  ]

  # Enhanced monitoring and logging
  enable_detailed_monitoring = true
  enable_cloudwatch_agent    = true

  # Security hardening
  require_imdsv2 = true

  # Additional IAM policies for RDS access
  additional_iam_policy_arns = [
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]

  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    ManagedBy   = "Terraform"
  }
}

# ===========================
# Example 3: Bastion with Existing SSH Key
# ===========================
# Use an existing EC2 key pair instead of generating a new one

module "bastion_existing_key" {
  source = "./modules/ec2"

  name       = "bastion-existing-key"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Use existing key pair
  create_ssh_key         = false
  existing_key_pair_name = "my-existing-key"

  allowed_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "dev"
  }
}

# ===========================
# Example 4: Bastion with Elastic IP
# ===========================
# Bastion host with a static public IP address

module "bastion_with_eip" {
  source = "./modules/ec2"

  name       = "bastion-with-eip"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"  # Public subnet
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Allocate Elastic IP
  allocate_eip = true

  # Allow SSH from anywhere (not recommended for production)
  allowed_cidr_blocks = ["0.0.0.0/0"]

  tags = {
    Environment = "dev"
  }
}

# ===========================
# Example 5: Bastion with Custom Security Group
# ===========================
# Use an existing security group instead of creating a new one

module "bastion_custom_sg" {
  source = "./modules/ec2"

  name       = "bastion-custom-sg"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Use existing security group
  create_security_group = false
  security_group_ids    = ["sg-0123456789abcdef0"]

  tags = {
    Environment = "dev"
  }
}

# ===========================
# Example 6: Bastion with Custom User Data
# ===========================
# Override the default user data script with custom initialization

module "bastion_custom_userdata" {
  source = "./modules/ec2"

  name       = "bastion-custom-userdata"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Custom user data script
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y postgresql15 mysql
    
    # Custom configuration
    echo "Custom bastion host" > /etc/motd
    
    # Install additional tools
    yum install -y htop vim git
  EOF

  allowed_cidr_blocks = ["10.0.0.0/8"]

  tags = {
    Environment = "dev"
  }
}

# ===========================
# Example 7: Multi-AZ Bastion Hosts
# ===========================
# Deploy bastion hosts in multiple availability zones for high availability

module "bastion_az1" {
  source = "./modules/ec2"

  name       = "bastion-az1"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef0"  # Subnet in AZ1
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  create_ssh_key      = true
  ssh_key_algorithm   = "RSA"
  ssm_parameter_name  = "/bastion-az1/ssh-private-key"

  allowed_security_group_ids = ["sg-0123456789abcdef0"]

  tags = {
    Environment      = "production"
    AvailabilityZone = "us-east-1a"
  }
}

module "bastion_az2" {
  source = "./modules/ec2"

  name       = "bastion-az2"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_id  = "subnet-0123456789abcdef1"  # Subnet in AZ2
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  create_ssh_key      = true
  ssh_key_algorithm   = "RSA"
  ssm_parameter_name  = "/bastion-az2/ssh-private-key"

  allowed_security_group_ids = ["sg-0123456789abcdef0"]

  tags = {
    Environment      = "production"
    AvailabilityZone = "us-east-1b"
  }
}

# ===========================
# Example Outputs
# ===========================

# Output connection information for basic bastion
output "basic_bastion_connection" {
  description = "Connection information for basic bastion"
  value = {
    instance_id         = module.basic_bastion.instance_id
    private_ip          = module.basic_bastion.private_ip
    ssm_session_command = module.basic_bastion.ssm_session_command
  }
}

# Output instructions for production bastion
output "production_bastion_instructions" {
  description = "Instructions for connecting to production bastion"
  value       = module.production_bastion.instructions
}

# Output private key retrieval command (sensitive)
output "basic_bastion_key_retrieval" {
  description = "Command to retrieve private key from SSM"
  value       = module.basic_bastion.retrieve_private_key_command
  sensitive   = true
}

