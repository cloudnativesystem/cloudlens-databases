# RDS PostgreSQL Terraform Module

This module creates an AWS RDS PostgreSQL instance with best practices for security, monitoring, and high availability.

## Features

- **Automated Password Management**: Generates secure random passwords and stores them in AWS Secrets Manager
- **Encryption**: Supports encryption at rest with AWS KMS (AWS-managed or customer-managed keys)
- **Monitoring**: Enhanced monitoring and CloudWatch logs export
- **Backup**: Automated backups with configurable retention periods
- **Network Security**: Configurable security groups and subnet groups for VPC isolation
- **High Availability**: Optional Multi-AZ deployment
- **Storage Autoscaling**: Automatic storage scaling to prevent running out of space
- **Parameter Groups**: Customizable PostgreSQL parameters
- **Performance Insights**: Optional Performance Insights for database performance monitoring

## Usage

### Basic Example

```hcl
module "rds_postgres" {
  source = "../../modules/rds"

  identifier = "my-postgres-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  engine_version    = "15.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  database_name   = "myapp"
  master_username = "dbadmin"

  allowed_security_group_ids = ["sg-12345678"]

  tags = {
    Environment = "dev"
    Project     = "myapp"
  }
}
```

### Production Example with Multi-AZ and Enhanced Monitoring

```hcl
module "rds_postgres_prod" {
  source = "../../modules/rds"

  identifier = "prod-postgres-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]

  engine_version         = "15.4"
  instance_class         = "db.r6g.xlarge"
  allocated_storage      = 100
  max_allocated_storage  = 1000
  storage_type           = "gp3"
  storage_encrypted      = true
  kms_key_id             = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  database_name   = "production"
  master_username = "dbadmin"

  multi_az                = true
  deletion_protection     = true
  backup_retention_period = 30

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  performance_insights_enabled    = true

  allowed_security_group_ids = ["sg-12345678", "sg-87654321"]

  tags = {
    Environment = "production"
    Project     = "myapp"
    Owner       = "platform-team"
  }
}
```

### Using Existing Security Group and Subnet Group

```hcl
module "rds_postgres_custom" {
  source = "../../modules/rds"

  identifier = "custom-postgres-db"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  create_security_group  = false
  vpc_security_group_ids = ["sg-existing-12345678"]

  create_db_subnet_group = false
  db_subnet_group_name   = "existing-subnet-group"

  engine_version    = "15.4"
  instance_class    = "db.t3.small"
  allocated_storage = 50

  tags = {
    Environment = "staging"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.0 |
| random | >= 3.5 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| random | >= 3.5 |

## Resources Created

- `aws_db_instance` - The RDS PostgreSQL instance
- `aws_db_subnet_group` - Database subnet group (optional)
- `aws_db_parameter_group` - Database parameter group (optional)
- `aws_security_group` - Security group for the RDS instance (optional)
- `aws_security_group_rule` - Security group rules for ingress/egress (optional)
- `aws_secretsmanager_secret` - Secret for storing database credentials
- `aws_secretsmanager_secret_version` - Secret version with credentials
- `aws_iam_role` - IAM role for enhanced monitoring (if enabled)
- `aws_iam_role_policy_attachment` - Attach monitoring policy to IAM role
- `random_password` - Generate secure master password

## Inputs

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| identifier | The name of the RDS instance | `string` |
| vpc_id | The VPC ID where the RDS instance will be created | `string` |
| subnet_ids | List of subnet IDs for the DB subnet group (minimum 2) | `list(string)` |

### Optional Variables - Engine Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| engine_version | PostgreSQL engine version (14.x or 15.x) | `string` | `"15.4"` |
| instance_class | The instance type of the RDS instance | `string` | `"db.t3.micro"` |
| allocated_storage | The allocated storage in gigabytes | `number` | `20` |
| max_allocated_storage | Upper limit for storage autoscaling (0 to disable) | `number` | `100` |
| storage_type | Storage type (standard, gp2, gp3, io1) | `string` | `"gp3"` |
| storage_encrypted | Enable encryption at rest | `bool` | `true` |
| kms_key_id | KMS key ARN for encryption (null for AWS-managed) | `string` | `null` |

### Optional Variables - Database Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| database_name | Name of the database to create | `string` | `"postgres"` |
| master_username | Username for the master DB user | `string` | `"postgres"` |
| master_password_length | Length of auto-generated password | `number` | `16` |
| port | Port for database connections | `number` | `5432` |

### Optional Variables - Network Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| publicly_accessible | Make instance publicly accessible | `bool` | `false` |
| multi_az | Enable Multi-AZ deployment | `bool` | `false` |
| create_db_subnet_group | Create a new DB subnet group | `bool` | `true` |
| db_subnet_group_name | Existing subnet group name (if not creating) | `string` | `null` |
| create_security_group | Create a new security group | `bool` | `true` |
| vpc_security_group_ids | Existing security group IDs (if not creating) | `list(string)` | `[]` |
| allowed_security_group_ids | Security groups allowed to access RDS | `list(string)` | `[]` |
| allowed_cidr_blocks | CIDR blocks allowed to access RDS | `list(string)` | `[]` |

### Optional Variables - Backup Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| backup_retention_period | Days to retain backups (0-35) | `number` | `7` |
| backup_window | Daily backup time window (HH:MM-HH:MM) | `string` | `"03:00-04:00"` |
| maintenance_window | Weekly maintenance window | `string` | `"mon:04:00-mon:05:00"` |
| skip_final_snapshot | Skip final snapshot on deletion | `bool` | `false` |
| copy_tags_to_snapshot | Copy tags to snapshots | `bool` | `true` |

### Optional Variables - Monitoring and Logging

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enabled_cloudwatch_logs_exports | Log types to export (postgresql, upgrade) | `list(string)` | `["postgresql"]` |
| monitoring_interval | Enhanced monitoring interval in seconds | `number` | `60` |
| performance_insights_enabled | Enable Performance Insights | `bool` | `false` |
| performance_insights_retention_period | Performance Insights retention (7 or 731 days) | `number` | `7` |
| performance_insights_kms_key_id | KMS key for Performance Insights encryption | `string` | `null` |

### Optional Variables - Parameter Group

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_parameter_group | Create a new parameter group | `bool` | `true` |
| parameter_group_name | Existing parameter group name (if not creating) | `string` | `null` |
| parameter_group_family | Parameter group family (postgres14, postgres15) | `string` | `"postgres15"` |
| parameters | List of DB parameters to apply | `list(object)` | `[]` |

### Optional Variables - Other

| Name | Description | Type | Default |
|------|-------------|------|---------|
| deletion_protection | Enable deletion protection | `bool` | `false` |
| auto_minor_version_upgrade | Auto-apply minor version upgrades | `bool` | `true` |
| apply_immediately | Apply changes immediately vs maintenance window | `bool` | `false` |
| secret_recovery_window_days | Secret recovery window (7-30 days) | `number` | `7` |
| tags | Map of tags to add to all resources | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The RDS instance ID |
| db_instance_arn | The ARN of the RDS instance |
| db_instance_endpoint | The connection endpoint (address:port) |
| db_instance_address | The hostname of the RDS instance |
| db_instance_port | The database port |
| db_instance_name | The database name |
| db_instance_username | The master username (sensitive) |
| db_credentials_secret_arn | ARN of Secrets Manager secret with credentials |
| db_credentials_secret_id | ID of Secrets Manager secret |
| db_credentials_secret_name | Name of Secrets Manager secret |
| security_group_id | ID of the created security group |
| security_group_arn | ARN of the created security group |
| db_subnet_group_id | ID of the DB subnet group |
| db_parameter_group_id | ID of the DB parameter group |
| connection_string | PostgreSQL connection string (sensitive) |

## Retrieving Database Credentials

The database credentials are stored in AWS Secrets Manager. To retrieve them:

### Using AWS CLI

```bash
aws secretsmanager get-secret-value \
  --secret-id <secret-arn-from-output> \
  --query SecretString \
  --output text | jq .
```

### Using Terraform Data Source

```hcl
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = module.rds_postgres.db_credentials_secret_id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}
```

## Security Considerations

1. **Encryption**: Always enable `storage_encrypted = true` for production databases
2. **Network Isolation**: Set `publicly_accessible = false` and use security groups to restrict access
3. **Deletion Protection**: Enable `deletion_protection = true` for production databases
4. **Backup Retention**: Set appropriate `backup_retention_period` (30 days recommended for production)
5. **Multi-AZ**: Enable `multi_az = true` for production high availability
6. **Secrets Management**: Database credentials are automatically stored in Secrets Manager
7. **Monitoring**: Enable enhanced monitoring and CloudWatch logs for production workloads

## License

This module is maintained by the CloudLens team.

