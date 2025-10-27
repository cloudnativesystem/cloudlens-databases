# outputs.tf
# Outputs for EC2 Bastion Host Module

# ===========================
# Instance Outputs
# ===========================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.bastion.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.bastion.arn
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.bastion.instance_state
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.bastion.instance_type
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.bastion.ami
}

output "availability_zone" {
  description = "Availability zone where the instance is deployed"
  value       = aws_instance.bastion.availability_zone
}

# ===========================
# Network Outputs
# ===========================

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.bastion.private_ip
}

output "private_dns" {
  description = "Private DNS name of the instance"
  value       = aws_instance.bastion.private_dns
}

output "public_ip" {
  description = "Public IP address of the instance (if allocated)"
  value       = var.allocate_eip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance (if allocated)"
  value       = aws_instance.bastion.public_dns
}

output "eip_id" {
  description = "ID of the Elastic IP (if allocated)"
  value       = var.allocate_eip ? aws_eip.bastion[0].id : null
}

output "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP (if allocated)"
  value       = var.allocate_eip ? aws_eip.bastion[0].allocation_id : null
}

# ===========================
# Security Outputs
# ===========================

output "security_group_id" {
  description = "ID of the security group (if created)"
  value       = var.create_security_group ? aws_security_group.bastion[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group (if created)"
  value       = var.create_security_group ? aws_security_group.bastion[0].arn : null
}

output "security_group_name" {
  description = "Name of the security group (if created)"
  value       = var.create_security_group ? aws_security_group.bastion[0].name : null
}

# ===========================
# SSH Key Outputs
# ===========================

output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = var.create_ssh_key ? aws_key_pair.bastion[0].key_name : var.existing_key_pair_name
}

output "key_pair_id" {
  description = "ID of the EC2 key pair (if created)"
  value       = var.create_ssh_key ? aws_key_pair.bastion[0].key_pair_id : null
}

output "key_pair_arn" {
  description = "ARN of the EC2 key pair (if created)"
  value       = var.create_ssh_key ? aws_key_pair.bastion[0].arn : null
}

output "key_pair_fingerprint" {
  description = "Fingerprint of the EC2 key pair (if created)"
  value       = var.create_ssh_key ? aws_key_pair.bastion[0].fingerprint : null
}

# ===========================
# SSM Parameter Outputs
# ===========================

output "ssm_parameter_name" {
  description = "Name of the SSM parameter storing the private key"
  value       = var.create_ssh_key ? aws_ssm_parameter.private_key[0].name : null
}

output "ssm_parameter_arn" {
  description = "ARN of the SSM parameter storing the private key"
  value       = var.create_ssh_key ? aws_ssm_parameter.private_key[0].arn : null
  sensitive   = true
}

output "ssm_parameter_version" {
  description = "Version of the SSM parameter"
  value       = var.create_ssh_key ? aws_ssm_parameter.private_key[0].version : null
}

# ===========================
# IAM Outputs
# ===========================

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.bastion.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.bastion.arn
}

output "iam_role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.bastion.id
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.bastion.name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.bastion.arn
}

output "iam_instance_profile_id" {
  description = "ID of the IAM instance profile"
  value       = aws_iam_instance_profile.bastion.id
}

# ===========================
# Connection Information
# ===========================

output "ssh_command" {
  description = "SSH command to connect to the bastion host (requires private key from SSM)"
  value       = var.create_ssh_key ? "ssh -i <path-to-private-key> ec2-user@${aws_instance.bastion.private_ip}" : "ssh -i <path-to-private-key> ec2-user@${aws_instance.bastion.private_ip}"
}

output "ssm_session_command" {
  description = "AWS CLI command to start SSM session"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id}"
}

output "retrieve_private_key_command" {
  description = "AWS CLI command to retrieve private key from SSM Parameter Store"
  value       = var.create_ssh_key ? "aws ssm get-parameter --name ${aws_ssm_parameter.private_key[0].name} --with-decryption --query Parameter.Value --output text" : null
  sensitive   = true
}

# ===========================
# Instructions Output
# ===========================

output "instructions" {
  description = "Instructions for connecting to the bastion host"
  value = var.create_ssh_key ? <<-EOT
Bastion Host Connection Instructions:
=====================================

Instance ID: ${aws_instance.bastion.id}
Private IP:  ${aws_instance.bastion.private_ip}
${var.allocate_eip ? "Public IP:   ${aws_eip.bastion[0].public_ip}" : ""}

Option 1: Connect via SSM Session Manager (Recommended - No SSH key needed)
---------------------------------------------------------------------------
aws ssm start-session --target ${aws_instance.bastion.id}

Option 2: Connect via SSH (Requires private key)
-------------------------------------------------
1. Retrieve private key from SSM Parameter Store:
   aws ssm get-parameter --name ${aws_ssm_parameter.private_key[0].name} --with-decryption --query Parameter.Value --output text > bastion-key.pem
   chmod 400 bastion-key.pem

2. Connect via SSH:
   ssh -i bastion-key.pem ec2-user@${aws_instance.bastion.private_ip}

3. IMPORTANT: Delete the private key file after use:
   rm bastion-key.pem

Connecting to RDS from Bastion:
-------------------------------
1. Get RDS credentials from Secrets Manager:
   aws secretsmanager get-secret-value --secret-id <rds-secret-arn> --query SecretString --output text | jq .

2. Connect to PostgreSQL:
   psql -h <rds-endpoint> -U <username> -d <database>
EOT
 : "Use existing key pair: ${var.existing_key_pair_name}"
}
