# CloudLens Databases

Infrastructure as Code (IaC) for CloudLens database resources using Terraform.

## Overview

This repository contains Terraform modules and configurations for provisioning and managing database infrastructure for the CloudLens project, including:

- **PostgreSQL RDS instances** for Hive Metastore metadata storage
- **EC2 Bastion Hosts** for secure database access
- Automated credential management with AWS Secrets Manager
- Automated SSH key generation and secure storage
- Security configurations (VPC, security groups, encryption)
- Monitoring and logging setup
- Backup and recovery configurations

## Repository Structure

```
cloudlens-databases/
├── modules/
│   ├── rds/                    # Reusable RDS PostgreSQL module
│   │   ├── main.tf             # Main resource definitions
│   │   ├── variables.tf        # Input variables
│   │   ├── outputs.tf          # Output values
│   │   ├── versions.tf         # Provider version constraints
│   │   ├── examples.tf         # Usage examples
│   │   └── README.md           # Module documentation
│   │
│   └── ec2/                    # Reusable EC2 Bastion module
│       ├── main.tf             # Main resource definitions
│       ├── variables.tf        # Input variables
│       ├── outputs.tf          # Output values
│       ├── versions.tf         # Provider version constraints
│       ├── user_data.sh        # Instance initialization script
│       ├── examples.tf         # Usage examples
│       └── README.md           # Module documentation
│
└── environments/
    └── dev/
        └── services/
            ├── rds/            # Development RDS instance
            │   ├── service_rds_main.tf      # Module invocation
            │   ├── service_rds_variables.tf # Variable definitions
            │   ├── service_rds_outputs.tf   # Output definitions
            │   ├── service_rds_locals.tf    # Local values
            │   ├── service_rds.tfvars       # Environment-specific values
            │   ├── validate.sh              # Pre-deployment validation
            │   ├── DEPLOYMENT_CHECKLIST.md  # Deployment checklist
            │   └── README.md                # Deployment guide
            │
            └── ec2/            # Development Bastion Host
                ├── service_ec2_main.tf      # Module invocation
                ├── service_ec2_variables.tf # Variable definitions
                ├── service_ec2_outputs.tf   # Output definitions
                ├── service_ec2_locals.tf    # Local values
                ├── service_ec2.tfvars       # Environment-specific values
                ├── validate.sh              # Pre-deployment validation
                ├── DEPLOYMENT_CHECKLIST.md  # Deployment checklist
                └── README.md                # Deployment guide
```

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- VPC with at least 2 subnets in different availability zones

### Deploy Development Infrastructure

#### 1. Deploy RDS Instance

```bash
cd environments/dev/services/rds

# Update service_rds.tfvars with your VPC, subnet, and KMS key details
terraform init
terraform plan -var-file="service_rds.tfvars"
terraform apply -var-file="service_rds.tfvars"

# Retrieve database credentials
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .
```

#### 2. Deploy Bastion Host

```bash
cd environments/dev/services/ec2

# Update service_ec2.tfvars with your VPC, subnet, and KMS key details
terraform init
terraform plan -var-file="service_ec2.tfvars"
terraform apply -var-file="service_ec2.tfvars"

# Connect via SSM Session Manager (recommended)
aws ssm start-session --target $(terraform output -raw instance_id)
```

#### 3. Connect to RDS from Bastion

```bash
# From within the bastion host (via SSM session)
# Retrieve RDS credentials
SECRET_ARN="<your-rds-secret-arn>"
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .

# Connect to PostgreSQL
psql -h <rds-endpoint> -U <username> -d <database>
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

### EC2 Bastion Host Module

A reusable Terraform module for creating secure EC2 bastion hosts for database access.

**Features**:
- Automated SSH key generation and secure storage in SSM Parameter Store
- SSM Session Manager support (no SSH keys required)
- Pre-installed database clients (PostgreSQL, MySQL)
- CloudWatch monitoring and logging
- Security hardening (IMDSv2, encrypted volumes, minimal IAM permissions)
- Flexible security group configuration
- Optional Elastic IP allocation

**Documentation**: See [modules/ec2/README.md](modules/ec2/README.md)

## Environments

### Development (dev)

Development environment configuration for testing and development purposes.

#### RDS Instance Configuration
- Instance: db.t3.micro
- Storage: 20 GB (autoscaling to 100 GB)
- Multi-AZ: Disabled
- Backup Retention: 7 days
- Deletion Protection: Disabled

**Documentation**: See [environments/dev/services/rds/README.md](environments/dev/services/rds/README.md)

#### Bastion Host Configuration
- Instance: t2.small
- Storage: 100 GB gp3 (encrypted)
- Network: Private subnet (no public IP)
- SSH Key: Auto-generated RSA 4096-bit
- Monitoring: CloudWatch detailed monitoring enabled
- Security: IMDSv2 required, encrypted volumes

**Documentation**: See [environments/dev/services/ec2/README.md](environments/dev/services/ec2/README.md)

## Security

### Implemented Security Measures

#### Database Security
- ✅ Encryption at rest using AWS KMS
- ✅ Credentials stored in AWS Secrets Manager
- ✅ VPC-only access (not publicly accessible)
- ✅ Security group-based access control
- ✅ Automated backups enabled
- ✅ Enhanced monitoring enabled
- ✅ CloudWatch logs export enabled

#### Bastion Host Security
- ✅ SSH keys auto-generated and stored in SSM Parameter Store (encrypted)
- ✅ SSM Session Manager for secure access without SSH keys
- ✅ IMDSv2 required for enhanced instance metadata security
- ✅ Encrypted EBS volumes with customer-managed KMS keys
- ✅ Private subnet deployment (no public IP)
- ✅ Minimal IAM permissions (least privilege)
- ✅ CloudWatch logging and monitoring
- ✅ Automatic security updates enabled

### Best Practices

1. **Never commit credentials or private keys** to version control
2. **Use SSM Session Manager** instead of SSH when possible
3. **Use Secrets Manager** to retrieve database credentials
4. **Rotate passwords and SSH keys** regularly
5. **Enable deletion protection** for production databases
6. **Use Multi-AZ** for production high availability
7. **Monitor CloudWatch** metrics and logs
8. **Test backup restoration** procedures regularly
9. **Restrict bastion access** to specific security groups or CIDR blocks
10. **Delete private keys** after retrieving from SSM (never store locally)

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

#### RDS Instance
- RDS Instance (db.t3.micro): ~$15/month
- Storage (20 GB gp3): ~$2.50/month
- Backup Storage: ~$2/month
- Enhanced Monitoring: ~$1.50/month
- **RDS Subtotal**: ~$21/month

#### Bastion Host
- EC2 Instance (t2.small): ~$17/month
- EBS Volume (100 GB gp3): ~$8/month
- CloudWatch Logs: ~$0.50/month
- Detailed Monitoring: ~$2/month
- **Bastion Subtotal**: ~$27.50/month

#### Total Development Environment
- **Total**: ~$48.50/month

### Cost Reduction Tips

1. **Stop instances when not in use** (RDS and EC2 can be stopped during off-hours)
2. **Use appropriate instance sizing** (t2.micro for bastion if light usage)
3. **Clean up old snapshots** and unused resources
4. **Use gp3 storage** instead of io1 (already implemented)
5. **Disable Performance Insights** for dev/test environments
6. **Reduce bastion volume size** to 50 GB if 100 GB is not needed
7. **Disable detailed monitoring** for non-critical environments (saves ~$2/month)

## Troubleshooting

### Common Issues

**Cannot connect to database**:
- Verify security group rules allow inbound traffic on port 5432
- Ensure client is in the same VPC or has VPN/Direct Connect access
- Check database status is "Available"
- Try connecting from the bastion host first

**Cannot connect to bastion via SSM**:
- Wait 5-10 minutes after instance launch for SSM agent to register
- Verify IAM instance profile has `AmazonSSMManagedInstanceCore` policy
- Check security group allows outbound HTTPS (port 443)
- Ensure subnet has route to internet (NAT gateway) or VPC endpoints for SSM

**Cannot retrieve SSH private key from SSM**:
- Check IAM permissions include `ssm:GetParameter` and `kms:Decrypt`
- Verify KMS key policy allows your IAM principal to decrypt
- Ensure you're using `--with-decryption` flag

**Terraform errors**:
- Ensure AWS credentials are configured correctly
- Verify VPC and subnet IDs are valid
- Check that RDS subnets are in different availability zones
- Verify KMS key ARN is correct and accessible

**High costs**:
- Review instance class sizing
- Check for unused snapshots
- Verify storage autoscaling limits
- Stop instances when not in use

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
