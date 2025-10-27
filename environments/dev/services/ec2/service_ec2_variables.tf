# service_ec2_variables.tf
# Variables for EC2 Bastion Host - Development Environment

# ===========================
# Required Variables
# ===========================

variable "name" {
  description = "Name of the bastion host"
  type        = string
  default     = "cloudlens-bastion"
}

variable "vpc_id" {
  description = "ID of the VPC where the bastion host will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet where the bastion host will be deployed"
  type        = string
}

variable "kms_key_id" {
  description = "ARN of the KMS key for EBS encryption and SSM parameter encryption"
  type        = string
}

# ===========================
# Instance Configuration
# ===========================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"
}

variable "ami_id" {
  description = "AMI ID to use for the instance. If null, uses the latest Amazon Linux 2023 AMI"
  type        = string
  default     = null
}

# ===========================
# Storage Configuration
# ===========================

variable "root_volume_type" {
  description = "Type of root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 100
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "root_volume_delete_on_termination" {
  description = "Whether to delete the root volume on instance termination"
  type        = bool
  default     = true
}

# ===========================
# Network Configuration
# ===========================

variable "create_security_group" {
  description = "Whether to create a security group for the bastion host"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance (used when create_security_group is false)"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to SSH to the bastion host"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = []
}

variable "allocate_eip" {
  description = "Whether to allocate and associate an Elastic IP with the bastion host"
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Whether to enable source/destination checking"
  type        = bool
  default     = true
}

# ===========================
# SSH Key Configuration
# ===========================

variable "create_ssh_key" {
  description = "Whether to create a new SSH key pair"
  type        = bool
  default     = true
}

variable "existing_key_pair_name" {
  description = "Name of existing EC2 key pair to use (only used when create_ssh_key is false)"
  type        = string
  default     = null
}

variable "ssh_key_algorithm" {
  description = "Algorithm for SSH key generation (RSA, ECDSA, ED25519)"
  type        = string
  default     = "RSA"
}

variable "ssh_key_rsa_bits" {
  description = "Number of bits for RSA key (only used when ssh_key_algorithm is RSA)"
  type        = number
  default     = 4096
}

variable "ssm_parameter_name" {
  description = "Name of SSM parameter to store private key. If null, uses /<name>/ssh-private-key"
  type        = string
  default     = null
}

# ===========================
# IAM Configuration
# ===========================

variable "additional_iam_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the instance role"
  type        = list(string)
  default     = []
}

# ===========================
# Monitoring and Logging
# ===========================

variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed CloudWatch monitoring (1-minute intervals)"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Whether to install and configure CloudWatch Agent for logs and metrics"
  type        = bool
  default     = true
}

# ===========================
# Security Configuration
# ===========================

variable "require_imdsv2" {
  description = "Whether to require IMDSv2 (Instance Metadata Service v2) for enhanced security"
  type        = bool
  default     = true
}

# ===========================
# User Data Configuration
# ===========================

variable "user_data" {
  description = "Custom user data script. If null, uses the default user_data.sh template"
  type        = string
  default     = null
}

# ===========================
# Environment Tags
# ===========================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "cloudlens"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "cloudlens"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
