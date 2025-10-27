# Development RDS PostgreSQL Instance for Hive Metastore

This directory contains the Terraform configuration for provisioning a PostgreSQL RDS instance in the development environment to store Hive Metastore metadata.

## Overview

This configuration uses the reusable RDS module located at `modules/rds` to create a PostgreSQL database instance with the following characteristics:

- **Purpose**: Store Hive Metastore metadata (tables, schemas, partitions, etc.)
- **Engine**: PostgreSQL 15.4
- **Instance Class**: db.t3.micro (suitable for development)
- **Storage**: 20 GB with autoscaling enabled up to 100 GB
- **Encryption**: Enabled with AWS-managed KMS key
- **Backup**: 7-day retention period
- **Monitoring**: Enhanced monitoring and CloudWatch logs enabled
- **Network**: VPC-only access (not publicly accessible)

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS Credentials**: Configured AWS credentials with appropriate permissions
2. **Terraform**: Version 1.5.0 or higher installed
3. **VPC Information**: 
   - VPC ID where the RDS instance will be deployed
   - At least 2 subnet IDs in different availability zones
   - Security group IDs of EC2 instances that need database access

## Configuration

### Step 1: Update Required Variables

Edit the `service_rds.tfvars` file and replace the placeholder values:

```hcl
# Replace with your actual VPC ID
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Replace with your actual subnet IDs (minimum 2, in different AZs)
subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy"
]

# Replace with security group IDs that need database access
allowed_security_group_ids = [
  "sg-xxxxxxxxxxxxxxxxx"  # EC2 instance security group
]
```

### Step 2: Review Configuration

Review the other settings in `service_rds.tfvars` and adjust as needed:

- **Instance sizing**: `instance_class`, `allocated_storage`
- **Backup settings**: `backup_retention_period`, `backup_window`
- **Monitoring**: `monitoring_interval`, `performance_insights_enabled`
- **Tags**: `environment`, `project`, `owner`, `additional_tags`

## Deployment

### Initialize Terraform

```bash
cd environments/dev/services/rds
terraform init
```

### Plan the Deployment

```bash
terraform plan -var-file="service_rds.tfvars"
```

Review the plan output to ensure all resources will be created as expected.

### Apply the Configuration

```bash
terraform apply -var-file="service_rds.tfvars"
```

Type `yes` when prompted to confirm the deployment.

### Deployment Time

The RDS instance typically takes 10-15 minutes to provision and become available.

## Accessing Database Credentials

The database credentials are automatically generated and stored securely in AWS Secrets Manager.

### Using AWS CLI

```bash
# Get the secret ARN from Terraform outputs
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)

# Retrieve the credentials
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq .
```

### Using AWS Console

1. Navigate to AWS Secrets Manager in the AWS Console
2. Find the secret named `cloudlens-metastore-credentials-*`
3. Click "Retrieve secret value" to view the credentials

### Credential Format

The secret contains a JSON object with the following fields:

```json
{
  "username": "metastore_admin",
  "password": "auto-generated-secure-password",
  "engine": "postgres",
  "host": "cloudlens-metastore.xxxxxxxxxx.region.rds.amazonaws.com",
  "port": 5432,
  "dbname": "metastore"
}
```

## Connecting to the Database

### From EC2 Instance (within VPC)

```bash
# Install PostgreSQL client
sudo yum install postgresql15 -y  # Amazon Linux
# or
sudo apt-get install postgresql-client-15 -y  # Ubuntu

# Connect using psql
psql -h <db_instance_address> -U metastore_admin -d metastore
```

### Connection String

```
postgresql://metastore_admin:<password>@<db_instance_address>:5432/metastore
```

Replace `<password>` and `<db_instance_address>` with values from Secrets Manager.

## Outputs

After deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `db_instance_endpoint` | Full endpoint (hostname:port) |
| `db_instance_address` | Database hostname |
| `db_instance_port` | Database port (5432) |
| `db_credentials_secret_arn` | ARN of the Secrets Manager secret |
| `security_group_id` | ID of the RDS security group |
| `connection_string` | PostgreSQL connection string (without password) |

View outputs:

```bash
terraform output
```

## Monitoring

### CloudWatch Logs

PostgreSQL logs are exported to CloudWatch Logs. View them in the AWS Console:

1. Navigate to CloudWatch > Log groups
2. Find log group: `/aws/rds/instance/cloudlens-metastore/postgresql`

### Enhanced Monitoring

Enhanced monitoring metrics are collected every 60 seconds. View them in:

1. RDS Console > Databases > cloudlens-metastore
2. Click on "Monitoring" tab
3. View enhanced monitoring metrics

### CloudWatch Alarms (Recommended)

Consider setting up CloudWatch alarms for:

- High CPU utilization
- Low free storage space
- High database connections
- Read/write latency

## Backup and Recovery

### Automated Backups

- **Retention**: 7 days
- **Backup Window**: 03:00-04:00 UTC daily
- **Snapshots**: Automatically created and retained

### Manual Snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier cloudlens-metastore \
  --db-snapshot-identifier cloudlens-metastore-manual-$(date +%Y%m%d-%H%M%S)
```

### Restore from Snapshot

Use the AWS Console or CLI to restore from a snapshot to a new instance.

## Maintenance

### Maintenance Window

- **Window**: Monday 04:00-05:00 UTC
- **Auto Minor Version Upgrade**: Enabled

### Modifying the Instance

1. Update values in `service_rds.tfvars`
2. Run `terraform plan -var-file="service_rds.tfvars"`
3. Review changes
4. Run `terraform apply -var-file="service_rds.tfvars"`

**Note**: Some changes (like instance class) may cause downtime.

## Security Best Practices

✅ **Implemented**:
- Encryption at rest enabled
- Not publicly accessible
- Credentials stored in Secrets Manager
- Security group restricts access
- Automated backups enabled
- Enhanced monitoring enabled

⚠️ **Recommendations**:
- Regularly rotate database passwords
- Review and audit security group rules
- Enable deletion protection for production
- Use Multi-AZ for production
- Implement least-privilege IAM policies

## Troubleshooting

### Cannot Connect to Database

1. Verify security group allows inbound traffic on port 5432
2. Ensure EC2 instance is in the same VPC
3. Check that the EC2 instance's security group is in `allowed_security_group_ids`
4. Verify the database is in "Available" state

### Terraform Errors

**Error**: "Subnet IDs must be in different availability zones"
- **Solution**: Ensure `subnet_ids` contains subnets from at least 2 different AZs

**Error**: "VPC not found"
- **Solution**: Verify the `vpc_id` is correct and exists in your AWS account

## Cost Estimation

Approximate monthly cost for this configuration (us-east-1):

- **RDS Instance** (db.t3.micro): ~$15/month
- **Storage** (20 GB gp3): ~$2.50/month
- **Backup Storage** (7 days): ~$2/month (depends on data size)
- **Enhanced Monitoring**: ~$1.50/month

**Total**: ~$21/month (may vary by region and usage)

## Cleanup

To destroy the RDS instance and all associated resources:

```bash
terraform destroy -var-file="service_rds.tfvars"
```

**Warning**: This will permanently delete the database. Ensure you have backups if needed.

## Support

For issues or questions:
- Review the module documentation: `modules/rds/README.md`
- Check AWS RDS documentation
- Contact the CloudLens team

