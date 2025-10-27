# outputs.tf
# Outputs for the RDS PostgreSQL module

# ===========================
# RDS Instance Outputs
# ===========================

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = aws_db_instance.this.engine_version_actual
}

# ===========================
# Secrets Manager Outputs
# ===========================

output "db_credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_id" {
  description = "The ID of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.id
}

output "db_credentials_secret_name" {
  description = "The name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.name
}

# ===========================
# Security Group Outputs
# ===========================

output "security_group_id" {
  description = "The ID of the security group created for the RDS instance (if create_security_group is true)"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "The ARN of the security group created for the RDS instance (if create_security_group is true)"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

# ===========================
# Subnet Group Outputs
# ===========================

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].id : null
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = var.create_db_subnet_group ? aws_db_subnet_group.this[0].arn : null
}

# ===========================
# Parameter Group Outputs
# ===========================

output "db_parameter_group_id" {
  description = "The db parameter group name"
  value       = var.create_parameter_group ? aws_db_parameter_group.this[0].id : null
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = var.create_parameter_group ? aws_db_parameter_group.this[0].arn : null
}

# ===========================
# Monitoring Outputs
# ===========================

output "enhanced_monitoring_iam_role_arn" {
  description = "The ARN of the IAM role for enhanced monitoring (if enabled)"
  value       = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
}

# ===========================
# Connection Information
# ===========================

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_db_instance.this.username}@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
  sensitive   = true
}
