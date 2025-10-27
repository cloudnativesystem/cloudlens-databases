# variables.tf
# Variables for EC2 Bastion Host Module

# ===========================
# Required Variables
# ===========================

variable "name" {
  description = "Name of the bastion host (used for resource naming and tagging)"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Name must be between 1 and 64 characters."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the bastion host will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,17}$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier (vpc-xxxxxxxx)."
  }
}

variable "subnet_id" {
  description = "ID of the subnet where the bastion host will be deployed"
  type        = string

  validation {
    condition     = can(regex("^subnet-[a-f0-9]{8,17}$", var.subnet_id))
    error_message = "Subnet ID must be a valid subnet identifier (subnet-xxxxxxxx)."
  }
}

variable "kms_key_id" {
  description = "ARN of the KMS key for EBS encryption and SSM parameter encryption"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.kms_key_id))
    error_message = "KMS key ID must be a valid KMS key ARN."
  }
}

# ===========================
# Instance Configuration
# ===========================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type (e.g., t2.small, t3.medium)."
  }
}

variable "ami_id" {
  description = "AMI ID to use for the instance. If null, uses the latest Amazon Linux 2023 AMI"
  type        = string
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-[a-f0-9]{8,17}$", var.ami_id))
    error_message = "AMI ID must be null or a valid AMI identifier (ami-xxxxxxxx)."
  }
}

# ===========================
# Storage Configuration
# ===========================

variable "root_volume_type" {
  description = "Type of root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
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

  validation {
    condition     = alltrue([for sg in var.security_group_ids : can(regex("^sg-[a-f0-9]{8,17}$", sg))])
    error_message = "All security group IDs must be valid (sg-xxxxxxxx)."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to SSH to the bastion host"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for sg in var.allowed_security_group_ids : can(regex("^sg-[a-f0-9]{8,17}$", sg))])
    error_message = "All security group IDs must be valid (sg-xxxxxxxx)."
  }
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All CIDR blocks must be valid CIDR notation."
  }
}

variable "allocate_eip" {
  description = "Whether to allocate and associate an Elastic IP with the bastion host"
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Whether to enable source/destination checking (disable for NAT instances)"
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

  validation {
    condition     = contains(["RSA", "ECDSA", "ED25519"], var.ssh_key_algorithm)
    error_message = "SSH key algorithm must be one of: RSA, ECDSA, ED25519."
  }
}

variable "ssh_key_rsa_bits" {
  description = "Number of bits for RSA key (only used when ssh_key_algorithm is RSA)"
  type        = number
  default     = 4096

  validation {
    condition     = contains([2048, 3072, 4096], var.ssh_key_rsa_bits)
    error_message = "RSA key bits must be one of: 2048, 3072, 4096."
  }
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

  validation {
    condition     = alltrue([for arn in var.additional_iam_policy_arns : can(regex("^arn:aws:iam::[0-9]{12}:policy/", arn)) || can(regex("^arn:aws:iam::aws:policy/", arn))])
    error_message = "All IAM policy ARNs must be valid ARNs."
  }
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
# Tags
# ===========================

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
