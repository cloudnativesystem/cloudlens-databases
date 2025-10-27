# main.tf
# Reusable RDS PostgreSQL Module for CloudLens Databases

# Generate a random password for the RDS master user
resource "random_password" "master_password" {
  length  = var.master_password_length
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the database credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.identifier}-credentials-"
  description             = "Database credentials for ${var.identifier}"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master_password.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.database_name
  })
}

# DB Subnet Group for VPC placement
resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${var.identifier}-subnet-group"
  description = "Database subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${var.identifier}-subnet-group"
    }
  )
}

# DB Parameter Group for PostgreSQL-specific configurations
resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name_prefix = "${var.identifier}-"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for RDS instance
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${var.identifier}-"
  description = "Security group for ${var.identifier} RDS instance"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules
resource "aws_security_group_rule" "ingress" {
  count = var.create_security_group && length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.this[0].id
  description              = "Allow PostgreSQL access from security group ${var.allowed_security_group_ids[count.index]}"
}

resource "aws_security_group_rule" "ingress_cidr" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.this[0].id
  description       = "Allow PostgreSQL access from CIDR blocks"
}

resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this[0].id
  description       = "Allow all outbound traffic"
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "enhanced_monitoring" {
  count = var.enabled_cloudwatch_logs_exports != null || var.monitoring_interval > 0 ? 1 : 0

  name_prefix        = "${var.identifier}-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring[0].json

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-monitoring-role"
    }
  )
}

data "aws_iam_policy_document" "enhanced_monitoring" {
  count = var.enabled_cloudwatch_logs_exports != null || var.monitoring_interval > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.enabled_cloudwatch_logs_exports != null || var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "this" {
  identifier = var.identifier

  # Engine configuration
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id           = var.kms_key_id
  max_allocated_storage = var.max_allocated_storage

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = random_password.master_password.result
  port     = var.port

  # Network configuration
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible

  # High availability
  multi_az = var.multi_az

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot  = var.copy_tags_to_snapshot

  # Monitoring and logging
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id = var.performance_insights_enabled && var.performance_insights_kms_key_id != null ? var.performance_insights_kms_key_id : null

  # Parameter and option groups
  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Apply changes immediately or during maintenance window
  apply_immediately = var.apply_immediately

  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )

  # Lifecycle
  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.enhanced_monitoring
  ]
}
