# service_rds.tfvars
# Development environment configuration for Hive Metastore RDS instance

# ===========================
# Required Variables
# ===========================
# NOTE: These values need to be updated with your actual VPC and subnet IDs

identifier = "cloudlens-metastore"

# IMPORTANT: Replace these with your actual VPC and subnet IDs
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID
subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",     # Replace with your first subnet ID (AZ 1)
  "subnet-yyyyyyyyyyyyyyyyy"      # Replace with your second subnet ID (AZ 2)
]

# ===========================
# Engine Configuration
# ===========================

engine_version         = "15.4"        # PostgreSQL 15.4 (latest stable)
instance_class         = "db.t3.micro" # Small instance for dev
allocated_storage      = 20            # 20 GB initial storage
max_allocated_storage  = 100           # Auto-scale up to 100 GB
storage_type           = "gp3"         # General Purpose SSD (gp3)
storage_encrypted      = true          # Enable encryption at rest
kms_key_id             = null          # Use AWS-managed KMS key

# ===========================
# Database Configuration
# ===========================

database_name          = "metastore"       # Database name for Hive Metastore
master_username        = "metastore_admin" # Master username
master_password_length = 16                # Auto-generated password length
port                   = 5432              # PostgreSQL default port

# ===========================
# Network Configuration
# ===========================

publicly_accessible = false # Not publicly accessible (VPC only)
multi_az            = false # Single-AZ for dev (set to true for production)

# Security group configuration
create_security_group = true

# IMPORTANT: Replace with security group IDs of EC2 instances that need access
allowed_security_group_ids = [
  # "sg-xxxxxxxxxxxxxxxxx"  # Example: EC2 instance security group
]

# Alternative: Allow access from specific CIDR blocks (use with caution)
allowed_cidr_blocks = [
  # "10.0.0.0/16"  # Example: VPC CIDR block
]

# ===========================
# Backup Configuration
# ===========================

backup_retention_period = 7                  # 7 days backup retention
backup_window           = "03:00-04:00"      # 3-4 AM UTC backup window
maintenance_window      = "mon:04:00-mon:05:00" # Monday 4-5 AM UTC maintenance
skip_final_snapshot     = true               # Skip final snapshot for dev (set to false for production)
copy_tags_to_snapshot   = true               # Copy tags to snapshots

# ===========================
# Monitoring and Logging
# ===========================

enabled_cloudwatch_logs_exports = ["postgresql"] # Export PostgreSQL logs to CloudWatch
monitoring_interval             = 60              # Enhanced monitoring every 60 seconds
performance_insights_enabled    = false           # Disable Performance Insights for dev (enable for production)
performance_insights_retention_period = 7         # 7 days retention if enabled

# ===========================
# Parameter Group
# ===========================

create_parameter_group = true
parameter_group_family = "postgres15"

# Custom PostgreSQL parameters (optional)
parameters = [
  # Example: Increase max connections
  # {
  #   name  = "max_connections"
  #   value = "200"
  #   apply_method = "pending-reboot"
  # },
  # Example: Set shared_buffers
  # {
  #   name  = "shared_buffers"
  #   value = "{DBInstanceClassMemory/32768}"
  #   apply_method = "pending-reboot"
  # }
]

# ===========================
# Other Configuration
# ===========================

deletion_protection        = false # Disable deletion protection for dev (enable for production)
auto_minor_version_upgrade = true  # Auto-apply minor version upgrades
apply_immediately          = false # Apply changes during maintenance window
secret_recovery_window_days = 7    # 7 days to recover deleted secrets

# ===========================
# Tags
# ===========================

environment = "dev"
project     = "cloudlens"
owner       = "cloudlens"

additional_tags = {
  # Add any additional custom tags here
  # CostCenter = "engineering"
  # Team       = "data-platform"
}
