# variables.tf
# Input variables for the RDS PostgreSQL module

# ===========================
# Required Variables
# ===========================

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.identifier))
    error_message = "The identifier must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "The VPC ID where the RDS instance will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for the DB subnet group."
  }
}

# ===========================
# Engine Configuration
# ===========================

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"

  validation {
    condition     = can(regex("^(14|15)\\.", var.engine_version))
    error_message = "Engine version must be PostgreSQL 14.x or 15.x."
  }
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 and 65536 GB."
  }
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage. Set to 0 to disable storage autoscaling"
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= 20
    error_message = "Max allocated storage must be 0 (disabled) or >= 20 GB."
  }
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1"], var.storage_type)
    error_message = "Storage type must be one of: standard, gp2, gp3, io1."
  }
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If not specified, uses the default AWS managed key"
  type        = string
  default     = null
}

# ===========================
# Database Configuration
# ===========================

variable "database_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "postgres"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "postgres"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.master_username))
    error_message = "Master username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "master_password_length" {
  description = "Length of the auto-generated master password"
  type        = number
  default     = 16

  validation {
    condition     = var.master_password_length >= 8 && var.master_password_length <= 128
    error_message = "Master password length must be between 8 and 128 characters."
  }
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 5432
}

# ===========================
# Network Configuration
# ===========================

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "create_db_subnet_group" {
  description = "Whether to create a database subnet group"
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. If not provided, one will be created with the identifier"
  type        = string
  default     = null
}

variable "create_security_group" {
  description = "Whether to create a security group for the RDS instance"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate. Used when create_security_group is false"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the RDS instance"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS instance"
  type        = list(string)
  default     = []
}

# ===========================
# Backup Configuration
# ===========================

variable "backup_retention_period" {
  description = "The days to retain backups for. Must be between 0 and 35"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created (e.g., 03:00-04:00)"
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_window))
    error_message = "Backup window must be in the format HH:MM-HH:MM (e.g., 03:00-04:00)."
  }
}

variable "maintenance_window" {
  description = "The window to perform maintenance in (e.g., mon:04:00-mon:05:00)"
  type        = string
  default     = "mon:04:00-mon:05:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "Maintenance window must be in the format ddd:HH:MM-ddd:HH:MM (e.g., mon:04:00-mon:05:00)."
  }
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "copy_tags_to_snapshot" {
  description = "Copy all Instance tags to snapshots"
  type        = bool
  default     = true
}

# ===========================
# Monitoring and Logging
# ===========================

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs. Valid values: postgresql, upgrade"
  type        = list(string)
  default     = ["postgresql"]

  validation {
    condition     = alltrue([for log in var.enabled_cloudwatch_logs_exports : contains(["postgresql", "upgrade"], log)])
    error_message = "Enabled CloudWatch logs exports must be one or more of: postgresql, upgrade."
  }
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected. Valid values: 0, 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data. Valid values: 7, 731 (2 years)"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention period must be 7 or 731 days."
  }
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

# ===========================
# Parameter Group
# ===========================

variable "create_parameter_group" {
  description = "Whether to create a parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate. Used when create_parameter_group is false"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "postgres15"

  validation {
    condition     = can(regex("^postgres(14|15)$", var.parameter_group_family))
    error_message = "Parameter group family must be postgres14 or postgres15."
  }
}

variable "parameters" {
  description = "A list of DB parameters to apply. Each element should be a map with 'name', 'value', and optionally 'apply_method'"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

# ===========================
# Secrets Manager
# ===========================

variable "secret_recovery_window_days" {
  description = "Number of days to retain the secret before permanent deletion"
  type        = number
  default     = 7

  validation {
    condition     = var.secret_recovery_window_days >= 7 && var.secret_recovery_window_days <= 30
    error_message = "Secret recovery window must be between 7 and 30 days."
  }
}

# ===========================
# Other Configuration
# ===========================

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
