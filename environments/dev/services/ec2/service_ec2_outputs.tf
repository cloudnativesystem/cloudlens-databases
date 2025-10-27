# service_ec2_outputs.tf
# Outputs for EC2 Bastion Host - Development Environment

# ===========================
# Instance Outputs
# ===========================

output "instance_id" {
  description = "ID of the EC2 bastion instance"
  value       = module.cloudlens_bastion.instance_id
}

output "instance_arn" {
  description = "ARN of the EC2 bastion instance"
  value       = module.cloudlens_bastion.instance_arn
}

output "instance_state" {
  description = "State of the EC2 bastion instance"
  value       = module.cloudlens_bastion.instance_state
}

output "instance_type" {
  description = "Instance type of the EC2 bastion instance"
  value       = module.cloudlens_bastion.instance_type
}

output "ami_id" {
  description = "AMI ID used for the bastion instance"
  value       = module.cloudlens_bastion.ami_id
}

output "availability_zone" {
  description = "Availability zone where the bastion instance is deployed"
  value       = module.cloudlens_bastion.availability_zone
}

# ===========================
# Network Outputs
# ===========================

output "private_ip" {
  description = "Private IP address of the bastion instance"
  value       = module.cloudlens_bastion.private_ip
}

output "private_dns" {
  description = "Private DNS name of the bastion instance"
  value       = module.cloudlens_bastion.private_dns
}

output "public_ip" {
  description = "Public IP address of the bastion instance (if allocated)"
  value       = module.cloudlens_bastion.public_ip
}

output "public_dns" {
  description = "Public DNS name of the bastion instance (if allocated)"
  value       = module.cloudlens_bastion.public_dns
}

output "eip_id" {
  description = "ID of the Elastic IP (if allocated)"
  value       = module.cloudlens_bastion.eip_id
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP (if allocated)"
  value       = module.cloudlens_bastion.eip_allocation_id
}

# ===========================
# Security Outputs
# ===========================

output "security_group_id" {
  description = "ID of the bastion security group (if created)"
  value       = module.cloudlens_bastion.security_group_id
}

output "security_group_arn" {
  description = "ARN of the bastion security group (if created)"
  value       = module.cloudlens_bastion.security_group_arn
}

output "security_group_name" {
  description = "Name of the bastion security group (if created)"
  value       = module.cloudlens_bastion.security_group_name
}

# ===========================
# SSH Key Outputs
# ===========================

output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = module.cloudlens_bastion.key_pair_name
}

output "key_pair_id" {
  description = "ID of the EC2 key pair (if created)"
  value       = module.cloudlens_bastion.key_pair_id
}

output "key_pair_arn" {
  description = "ARN of the EC2 key pair (if created)"
  value       = module.cloudlens_bastion.key_pair_arn
}

output "key_pair_fingerprint" {
  description = "Fingerprint of the EC2 key pair (if created)"
  value       = module.cloudlens_bastion.key_pair_fingerprint
}

# ===========================
# SSM Parameter Outputs
# ===========================

output "ssm_parameter_name" {
  description = "Name of the SSM parameter storing the private key"
  value       = module.cloudlens_bastion.ssm_parameter_name
}

output "ssm_parameter_arn" {
  description = "ARN of the SSM parameter storing the private key"
  value       = module.cloudlens_bastion.ssm_parameter_arn
  sensitive   = true
}

output "ssm_parameter_version" {
  description = "Version of the SSM parameter"
  value       = module.cloudlens_bastion.ssm_parameter_version
}

# ===========================
# IAM Outputs
# ===========================

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.cloudlens_bastion.iam_role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.cloudlens_bastion.iam_role_arn
}

output "iam_role_id" {
  description = "ID of the IAM role"
  value       = module.cloudlens_bastion.iam_role_id
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = module.cloudlens_bastion.iam_instance_profile_name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = module.cloudlens_bastion.iam_instance_profile_arn
}

output "iam_instance_profile_id" {
  description = "ID of the IAM instance profile"
  value       = module.cloudlens_bastion.iam_instance_profile_id
}

# ===========================
# Connection Information
# ===========================

output "ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = module.cloudlens_bastion.ssh_command
}

output "ssm_session_command" {
  description = "AWS CLI command to start SSM session"
  value       = module.cloudlens_bastion.ssm_session_command
}

output "retrieve_private_key_command" {
  description = "AWS CLI command to retrieve private key from SSM Parameter Store"
  value       = module.cloudlens_bastion.retrieve_private_key_command
  sensitive   = true
}

# ===========================
# Instructions Output
# ===========================

output "instructions" {
  description = "Instructions for connecting to the bastion host and RDS"
  value       = module.cloudlens_bastion.instructions
}
