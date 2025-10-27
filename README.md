# CloudLens Databases

Infrastructure as Code (IaC) for CloudLens database resources using Terraform.

## Overview

This repository contains Terraform modules and configurations for provisioning and managing database infrastructure for the CloudLens project, including:

- **PostgreSQL RDS instances** for Hive Metastore metadata storage
- Automated credential management with AWS Secrets Manager
- Security configurations (VPC, security groups, encryption)
- Monitoring and logging setup
- Backup and recovery configurations

## Repository Structure

```
cloudlens-databases/
├── modules/
│   └── rds/                    # Reusable RDS PostgreSQL module
│       ├── main.tf             # Main resource definitions
│       ├── variables.tf        # Input variables
│       ├── outputs.tf          # Output values
│       ├── versions.tf         # Provider version constraints
│       └── README.md           # Module documentation
│
└── environments/
    └── dev/
        └── services/
            └── rds/            # Development RDS instance
                ├── service_rds_main.tf      # Module invocation
                ├── service_rds_variables.tf # Variable definitions
                ├── service_rds_outputs.tf   # Output definitions
                ├── service_rds_locals.tf    # Local values
                ├── service_rds.tfvars       # Environment-specific values
                └── README.md                # Deployment guide
```

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- VPC with at least 2 subnets in different availability zones

### Deploy Development RDS Instance

1. **Navigate to the dev environment**:
   ```bash
   cd environments/dev/services/rds
   ```

2. **Update configuration**:
   Edit `service_rds.tfvars` and replace placeholder values:
   - `vpc_id`: Your VPC ID
   - `subnet_ids`: Your subnet IDs (minimum 2)
   - `allowed_security_group_ids`: Security groups that need database access

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan -var-file="service_rds.tfvars"
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply -var-file="service_rds.tfvars"
   ```

6. **Retrieve database credentials**:
   ```bash
   SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)
   aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .
   ```

## Modules

### RDS PostgreSQL Module

A reusable Terraform module for creating PostgreSQL RDS instances with best practices.

**Features**:
- Automated password generation and secure storage
- Encryption at rest with KMS
- Enhanced monitoring and CloudWatch logs
- Automated backups with configurable retention
- VPC isolation and security group management
- Storage autoscaling
- Multi-AZ support for high availability

**Documentation**: See [modules/rds/README.md](modules/rds/README.md)

## Environments

### Development (dev)

Development environment configuration for testing and development purposes.

**Configuration**:
- Instance: db.t3.micro
- Storage: 20 GB (autoscaling to 100 GB)
- Multi-AZ: Disabled
- Backup Retention: 7 days
- Deletion Protection: Disabled

**Documentation**: See [environments/dev/services/rds/README.md](environments/dev/services/rds/README.md)

## Security

### Implemented Security Measures

- ✅ Encryption at rest using AWS KMS
- ✅ Credentials stored in AWS Secrets Manager
- ✅ VPC-only access (not publicly accessible)
- ✅ Security group-based access control
- ✅ Automated backups enabled
- ✅ Enhanced monitoring enabled
- ✅ CloudWatch logs export enabled

### Best Practices

1. **Never commit credentials** to version control
2. **Use Secrets Manager** to retrieve database credentials
3. **Rotate passwords** regularly
4. **Enable deletion protection** for production databases
5. **Use Multi-AZ** for production high availability
6. **Monitor CloudWatch** metrics and logs
7. **Test backup restoration** procedures regularly

## Monitoring

### CloudWatch Metrics

All RDS instances export metrics to CloudWatch:
- CPU utilization
- Database connections
- Free storage space
- Read/write IOPS
- Network throughput

### CloudWatch Logs

PostgreSQL logs are exported to CloudWatch Logs for analysis and troubleshooting.

### Enhanced Monitoring

Enhanced monitoring provides OS-level metrics at 60-second intervals.

## Backup and Recovery

### Automated Backups

- **Retention**: 7 days (configurable)
- **Backup Window**: 03:00-04:00 UTC
- **Snapshots**: Automatically created and retained

### Manual Snapshots

Create manual snapshots for important milestones:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier cloudlens-metastore \
  --db-snapshot-identifier cloudlens-metastore-manual-$(date +%Y%m%d)
```

## Cost Optimization

### Development Environment

Approximate monthly cost (us-east-1):
- RDS Instance (db.t3.micro): ~$15/month
- Storage (20 GB gp3): ~$2.50/month
- Backup Storage: ~$2/month
- Enhanced Monitoring: ~$1.50/month
- **Total**: ~$21/month

### Cost Reduction Tips

1. Stop non-production instances when not in use
2. Use appropriate instance sizing
3. Clean up old snapshots
4. Use gp3 storage instead of io1
5. Disable Performance Insights for dev/test

## Troubleshooting

### Common Issues

**Cannot connect to database**:
- Verify security group rules allow inbound traffic on port 5432
- Ensure client is in the same VPC or has VPN/Direct Connect access
- Check database status is "Available"

**Terraform errors**:
- Ensure AWS credentials are configured correctly
- Verify VPC and subnet IDs are valid
- Check that subnets are in different availability zones

**High costs**:
- Review instance class sizing
- Check for unused snapshots
- Verify storage autoscaling limits

## Contributing

When adding new database resources:

1. Create reusable modules in `modules/`
2. Document module usage in module README
3. Add environment-specific configurations in `environments/`
4. Follow Terraform best practices
5. Test in dev environment before production

## Support

For questions or issues:
- Review module documentation in `modules/rds/README.md`
- Check environment-specific README files
- Consult AWS RDS documentation
- Contact the CloudLens platform team

## License

Maintained by the CloudLens team.
