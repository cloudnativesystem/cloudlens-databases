# service_rds_main.tf
# Development environment RDS PostgreSQL instance for Hive Metastore

module "hive_metastore_rds" {
  source = "../../../../modules/rds"

  # Instance identification
  identifier = var.identifier

  # Network configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Engine configuration
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = var.storage_type
  storage_encrypted      = var.storage_encrypted
  kms_key_id             = var.kms_key_id

  # Database configuration
  database_name          = var.database_name
  master_username        = var.master_username
  master_password_length = var.master_password_length
  port                   = var.port

  # Network security
  publicly_accessible        = var.publicly_accessible
  multi_az                   = var.multi_az
  create_security_group      = var.create_security_group
  allowed_security_group_ids = var.allowed_security_group_ids
  allowed_cidr_blocks        = var.allowed_cidr_blocks

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  copy_tags_to_snapshot   = var.copy_tags_to_snapshot

  # Monitoring and logging
  enabled_cloudwatch_logs_exports        = var.enabled_cloudwatch_logs_exports
  monitoring_interval                    = var.monitoring_interval
  performance_insights_enabled           = var.performance_insights_enabled
  performance_insights_retention_period  = var.performance_insights_retention_period

  # Parameter group
  create_parameter_group = var.create_parameter_group
  parameter_group_family = var.parameter_group_family
  parameters             = var.parameters

  # Other settings
  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  secret_recovery_window_days = var.secret_recovery_window_days

  # Tags
  tags = local.tags
}
