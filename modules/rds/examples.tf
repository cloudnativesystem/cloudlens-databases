# examples.tf
# Example configurations for using the RDS PostgreSQL module
# These are examples only - do not apply directly

# ===========================
# Example 1: Basic Development Instance
# ===========================

module "rds_dev_basic" {
  source = "../modules/rds"

  identifier = "myapp-dev-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Use defaults for most settings
  allowed_security_group_ids = ["sg-12345678"]

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}

# ===========================
# Example 2: Production Instance with High Availability
# ===========================

module "rds_prod_ha" {
  source = "../modules/rds"

  identifier = "myapp-prod-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]

  # Production-grade instance
  engine_version         = "15.4"
  instance_class         = "db.r6g.xlarge"
  allocated_storage      = 100
  max_allocated_storage  = 1000
  storage_type           = "gp3"
  storage_encrypted      = true
  kms_key_id             = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # High availability
  multi_az            = true
  deletion_protection = true

  # Extended backup retention
  backup_retention_period = 30
  skip_final_snapshot     = false

  # Enhanced monitoring and insights
  monitoring_interval          = 60
  performance_insights_enabled = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  allowed_security_group_ids = ["sg-app-servers", "sg-admin-access"]

  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
    Compliance  = "required"
  }
}

# ===========================
# Example 3: Using Existing Security Group and Subnet Group
# ===========================

module "rds_custom_networking" {
  source = "../modules/rds"

  identifier = "myapp-staging-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Use existing security group
  create_security_group  = false
  vpc_security_group_ids = ["sg-existing-db-access"]

  # Use existing subnet group
  create_db_subnet_group = false
  db_subnet_group_name   = "existing-db-subnet-group"

  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 50

  tags = {
    Environment = "staging"
  }
}

# ===========================
# Example 4: Custom PostgreSQL Parameters
# ===========================

module "rds_custom_params" {
  source = "../modules/rds"

  identifier = "myapp-analytics-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  instance_class    = "db.r6g.2xlarge"
  allocated_storage = 500

  # Custom parameter group with tuned settings
  create_parameter_group = true
  parameter_group_family = "postgres15"
  
  parameters = [
    {
      name         = "max_connections"
      value        = "500"
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_buffers"
      value        = "{DBInstanceClassMemory/4096}"
      apply_method = "pending-reboot"
    },
    {
      name         = "effective_cache_size"
      value        = "{DBInstanceClassMemory/2048}"
      apply_method = "immediate"
    },
    {
      name         = "maintenance_work_mem"
      value        = "2097152"  # 2GB in KB
      apply_method = "immediate"
    },
    {
      name         = "work_mem"
      value        = "65536"  # 64MB in KB
      apply_method = "immediate"
    },
    {
      name         = "random_page_cost"
      value        = "1.1"  # Optimized for SSD
      apply_method = "immediate"
    }
  ]

  allowed_security_group_ids = ["sg-analytics-servers"]

  tags = {
    Environment = "production"
    Workload    = "analytics"
  }
}

# ===========================
# Example 5: Minimal Cost Development Instance
# ===========================

module "rds_minimal_cost" {
  source = "../modules/rds"

  identifier = "myapp-test-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Smallest instance
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  # Minimal monitoring
  monitoring_interval             = 0  # Disable enhanced monitoring
  performance_insights_enabled    = false
  enabled_cloudwatch_logs_exports = []  # Disable log exports

  # Minimal backup
  backup_retention_period = 1
  skip_final_snapshot     = true

  # No deletion protection
  deletion_protection = false

  allowed_cidr_blocks = ["10.0.0.0/16"]

  tags = {
    Environment = "test"
    CostCenter  = "development"
  }
}

# ===========================
# Example 6: Hive Metastore Configuration
# ===========================

module "rds_hive_metastore" {
  source = "../modules/rds"

  identifier = "hive-metastore-prod"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]

  # Sized for Hive Metastore workload
  engine_version    = "15.4"
  instance_class    = "db.r6g.large"
  allocated_storage = 100
  max_allocated_storage = 500

  # Database configuration
  database_name   = "metastore"
  master_username = "hive"
  port            = 5432

  # High availability for production
  multi_az            = true
  deletion_protection = true

  # Backup configuration
  backup_retention_period = 14
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Monitoring
  monitoring_interval             = 60
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Hive-specific parameters
  parameters = [
    {
      name         = "max_connections"
      value        = "300"
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_buffers"
      value        = "{DBInstanceClassMemory/8192}"
      apply_method = "pending-reboot"
    }
  ]

  allowed_security_group_ids = [
    "sg-emr-master",
    "sg-emr-core",
    "sg-hive-clients"
  ]

  tags = {
    Environment = "production"
    Service     = "hive-metastore"
    Owner       = "data-platform"
  }
}

# ===========================
# Example 7: Using Custom KMS Key for Encryption
# ===========================

# First, create a KMS key (or use existing)
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "rds-encryption-key"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/rds-encryption"
  target_key_id = aws_kms_key.rds.key_id
}

module "rds_custom_kms" {
  source = "../modules/rds"

  identifier = "myapp-secure-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # Use custom KMS key
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # Also use for Performance Insights
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  instance_class    = "db.t3.medium"
  allocated_storage = 100

  allowed_security_group_ids = ["sg-12345678"]

  tags = {
    Environment = "production"
    Compliance  = "pci-dss"
  }
}

# ===========================
# Outputs Example
# ===========================

# Access module outputs
output "database_endpoint" {
  value = module.rds_dev_basic.db_instance_endpoint
}

output "secret_arn" {
  value = module.rds_dev_basic.db_credentials_secret_arn
}

output "connection_info" {
  value = {
    host     = module.rds_dev_basic.db_instance_address
    port     = module.rds_dev_basic.db_instance_port
    database = module.rds_dev_basic.db_instance_name
    username = module.rds_dev_basic.db_instance_username
  }
  sensitive = true
}

