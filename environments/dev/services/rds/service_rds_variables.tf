# service_rds_variables.tf
# Variables for the development RDS instance

# ===========================
# Required Variables
# ===========================

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the RDS instance will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

# ===========================
# Engine Configuration
# ===========================

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
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
}

variable "max_allocated_storage" {
  description = "The upper limit for storage autoscaling"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption (null for AWS-managed)"
  type        = string
  default     = null
}

# ===========================
# Database Configuration
# ===========================

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "metastore"
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "metastore_admin"
}

variable "master_password_length" {
  description = "Length of auto-generated password"
  type        = number
  default     = 16
}

variable "port" {
  description = "Port for database connections"
  type        = number
  default     = 5432
}

# ===========================
# Network Configuration
# ===========================

variable "publicly_accessible" {
  description = "Make instance publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Create a new security group"
  type        = bool
  default     = true
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to access RDS"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access RDS"
  type        = list(string)
  default     = []
}

# ===========================
# Backup Configuration
# ===========================

variable "backup_retention_period" {
  description = "Days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily backup time window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly maintenance window"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

# ===========================
# Monitoring and Logging
# ===========================

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 60
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period"
  type        = number
  default     = 7
}

# ===========================
# Parameter Group
# ===========================

variable "create_parameter_group" {
  description = "Create a new parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "postgres15"
}

variable "parameters" {
  description = "List of DB parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

# ===========================
# Other Configuration
# ===========================

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Auto-apply minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "secret_recovery_window_days" {
  description = "Secret recovery window in days"
  type        = number
  default     = 7
}

# ===========================
# Environment Tags
# ===========================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "cloudlens"
}

variable "owner" {
  description = "Owner/team name"
  type        = string
  default     = "cloudlens"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
