# service_rds_outputs.tf
# Outputs for the development RDS instance

# ===========================
# RDS Instance Outputs
# ===========================

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = module.hive_metastore_rds.db_instance_id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.hive_metastore_rds.db_instance_arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = module.hive_metastore_rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = module.hive_metastore_rds.db_instance_address
}

output "db_instance_port" {
  description = "The database port"
  value       = module.hive_metastore_rds.db_instance_port
}

output "db_instance_name" {
  description = "The database name"
  value       = module.hive_metastore_rds.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.hive_metastore_rds.db_instance_username
  sensitive   = true
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = module.hive_metastore_rds.db_instance_engine_version
}

# ===========================
# Secrets Manager Outputs
# ===========================

output "db_credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database credentials"
  value       = module.hive_metastore_rds.db_credentials_secret_arn
}

output "db_credentials_secret_id" {
  description = "The ID of the Secrets Manager secret containing database credentials"
  value       = module.hive_metastore_rds.db_credentials_secret_id
}

output "db_credentials_secret_name" {
  description = "The name of the Secrets Manager secret containing database credentials"
  value       = module.hive_metastore_rds.db_credentials_secret_name
}

# ===========================
# Security Group Outputs
# ===========================

output "security_group_id" {
  description = "The ID of the security group for the RDS instance"
  value       = module.hive_metastore_rds.security_group_id
}

output "security_group_arn" {
  description = "The ARN of the security group for the RDS instance"
  value       = module.hive_metastore_rds.security_group_arn
}

# ===========================
# Connection Information
# ===========================

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = module.hive_metastore_rds.connection_string
  sensitive   = true
}

# ===========================
# Instructions
# ===========================

output "instructions" {
  description = "Instructions for retrieving database credentials"
  value = <<-EOT
    To retrieve the database credentials, use the following AWS CLI command:

    aws secretsmanager get-secret-value \
      --secret-id ${module.hive_metastore_rds.db_credentials_secret_arn} \
      --query SecretString \
      --output text | jq .

    Or use the Secrets Manager console:
    https://console.aws.amazon.com/secretsmanager/home?region=<your-region>#/secret?name=${module.hive_metastore_rds.db_credentials_secret_name}
  EOT
}
