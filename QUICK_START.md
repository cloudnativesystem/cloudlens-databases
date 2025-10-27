# Quick Start Guide - CloudLens Database Infrastructure

## 🚀 Deploy Complete Infrastructure

This guide covers deploying both the RDS PostgreSQL database and the EC2 bastion host for secure access.

### Prerequisites
- ✅ Terraform >= 1.5.0
- ✅ AWS CLI configured
- ✅ VPC with 2+ subnets in different AZs
- ✅ KMS key for encryption

## Option A: Deploy RDS Only (5 minutes)

### Step 1: Update RDS Configuration (2 minutes)

```bash
cd environments/dev/services/rds
```

Edit `service_rds.tfvars` and replace these values:

```hcl
vpc_id = "vpc-YOUR_VPC_ID_HERE"
subnet_ids = ["subnet-YOUR_SUBNET_1_HERE", "subnet-YOUR_SUBNET_2_HERE"]
allowed_security_group_ids = ["sg-YOUR_EC2_SECURITY_GROUP_HERE"]
```

### Step 2: Deploy RDS (2 minutes + 10-15 min wait)

```bash
./validate.sh
terraform init
terraform plan -var-file="service_rds.tfvars"
terraform apply -var-file="service_rds.tfvars"
```

### Step 3: Get Credentials (30 seconds)

```bash
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .
```

## Option B: Deploy RDS + Bastion Host (10 minutes)

### Step 1: Deploy RDS (follow Option A above)

### Step 2: Update Bastion Configuration (2 minutes)

```bash
cd environments/dev/services/ec2
```

Edit `service_ec2.tfvars` and replace these values:

```hcl
vpc_id = "vpc-YOUR_VPC_ID_HERE"
subnet_id = "subnet-YOUR_PRIVATE_SUBNET_HERE"  # Private subnet
kms_key_id = "arn:aws:kms:REGION:ACCOUNT:key/KEY_ID"
allowed_security_group_ids = ["sg-YOUR_VPN_SG_HERE"]  # Or use allowed_cidr_blocks
```

### Step 3: Deploy Bastion (2 minutes + 3-5 min wait)

```bash
./validate.sh
terraform init
terraform plan -var-file="service_ec2.tfvars"
terraform apply -var-file="service_ec2.tfvars"
```

### Step 4: Connect to Bastion (30 seconds)

```bash
# Option 1: SSM Session Manager (recommended - no SSH key needed)
aws ssm start-session --target $(terraform output -raw instance_id)

# Option 2: SSH (requires retrieving private key from SSM)
SSM_PARAM=$(terraform output -raw ssm_parameter_name)
aws ssm get-parameter --name $SSM_PARAM --with-decryption \
  --query Parameter.Value --output text > bastion-key.pem
chmod 400 bastion-key.pem
ssh -i bastion-key.pem ec2-user@$(terraform output -raw private_ip)
rm bastion-key.pem  # Delete after use
```

### Step 5: Connect to RDS from Bastion (1 minute)

```bash
# From within the bastion host (via SSM session)
SECRET_ARN="<your-rds-secret-arn>"
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .

# Connect to PostgreSQL
psql -h <rds-endpoint> -U metastore_admin -d metastore
```

## 📋 What You Get

### RDS PostgreSQL Database
- **Database**: PostgreSQL 15.4
- **Instance**: db.t3.micro (suitable for dev)
- **Storage**: 20 GB (auto-scales to 100 GB)
- **Encryption**: ✅ Enabled with KMS
- **Backups**: ✅ 7 days retention
- **Monitoring**: ✅ Enhanced monitoring + CloudWatch logs
- **Cost**: ~$21/month

### EC2 Bastion Host (Optional)
- **Instance**: t2.small (Amazon Linux 2023)
- **Storage**: 100 GB gp3 (encrypted)
- **SSH Key**: Auto-generated RSA 4096-bit (stored in SSM)
- **Access**: SSM Session Manager + SSH
- **Security**: IMDSv2, private subnet, encrypted volumes
- **Tools**: PostgreSQL client, MySQL client, AWS CLI v2
- **Cost**: ~$27.50/month

### Total Cost
- **RDS Only**: ~$21/month
- **RDS + Bastion**: ~$48.50/month

## 🔌 Connect to Database

### Option 1: From Bastion Host (Recommended)

```bash
# 1. Connect to bastion via SSM
aws ssm start-session --target <bastion-instance-id>

# 2. Get RDS credentials
SECRET_ARN="<your-rds-secret-arn>"
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .

# 3. Connect to PostgreSQL (psql is pre-installed)
psql -h <rds-endpoint> -U metastore_admin -d metastore
```

### Option 2: Port Forwarding via SSM

```bash
# Forward RDS port to your local machine
aws ssm start-session \
  --target <bastion-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'

# In another terminal, connect to localhost
psql -h localhost -U metastore_admin -d metastore
```

### Option 3: From EC2 Instance (in same VPC)

```bash
# Install PostgreSQL client
sudo yum install postgresql15 -y

# Get connection details from Secrets Manager
HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .host)
PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .password)

# Connect
PGPASSWORD=$PASSWORD psql -h $HOST -U metastore_admin -d metastore
```

## 📊 View Outputs

```bash
# All outputs
terraform output

# Specific output
terraform output db_instance_endpoint
terraform output db_credentials_secret_arn
```

## 🔍 Verify Deployment

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier cloudlens-metastore \
  --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table

# View CloudWatch logs
aws logs tail /aws/rds/instance/cloudlens-metastore/postgresql --follow
```

## 🛠️ Common Commands

### View Database Status
```bash
aws rds describe-db-instances --db-instance-identifier cloudlens-metastore
```

### Create Manual Snapshot
```bash
aws rds create-db-snapshot \
  --db-instance-identifier cloudlens-metastore \
  --db-snapshot-identifier cloudlens-metastore-manual-$(date +%Y%m%d)
```

### Modify Instance (e.g., change instance class)
```bash
# Update service_rds.tfvars, then:
terraform plan -var-file="service_rds.tfvars"
terraform apply -var-file="service_rds.tfvars"
```

### Destroy Infrastructure
```bash
terraform destroy -var-file="service_rds.tfvars"
```
⚠️ **Warning**: This permanently deletes the database!

## 📚 Documentation

- **Full Documentation**: `README.md`
- **Module Details**: `modules/rds/README.md`
- **Deployment Guide**: `environments/dev/services/rds/README.md`
- **Deployment Checklist**: `environments/dev/services/rds/DEPLOYMENT_CHECKLIST.md`
- **Complete Summary**: `DEPLOYMENT_SUMMARY.md`

## 🐛 Troubleshooting

### Cannot connect to database
- ✅ Verify security group allows port 5432
- ✅ Check EC2 security group is in `allowed_security_group_ids`
- ✅ Ensure database status is "available"
- ✅ Try connecting from bastion host first

### Cannot connect to bastion via SSM
- ✅ Wait 5-10 minutes after instance launch
- ✅ Verify IAM instance profile has SSM permissions
- ✅ Check security group allows outbound HTTPS (port 443)
- ✅ Ensure subnet has route to internet or VPC endpoints

### Cannot retrieve SSH private key
- ✅ Check IAM permissions include `ssm:GetParameter` and `kms:Decrypt`
- ✅ Verify KMS key policy allows decryption
- ✅ Use `--with-decryption` flag

### Terraform errors
- ✅ Run `./validate.sh` to check configuration
- ✅ Verify VPC and subnet IDs are correct
- ✅ Ensure RDS subnets are in different AZs
- ✅ Verify KMS key ARN is correct

### Need help?
- Check `environments/dev/services/rds/README.md` for RDS troubleshooting
- Check `environments/dev/services/ec2/README.md` for bastion troubleshooting
- Review AWS documentation
- Contact CloudLens platform team

## 💰 Cost Optimization

**Development** (~$48.50/month total):
- RDS: ~$21/month
- Bastion: ~$27.50/month
- Current configuration is already optimized for dev

**To reduce costs further**:
```hcl
# RDS (service_rds.tfvars):
monitoring_interval = 0              # Disable enhanced monitoring (-$1.50/month)
enabled_cloudwatch_logs_exports = [] # Disable log exports (-$0.50/month)
backup_retention_period = 1          # Minimal backups (-$1/month)

# Bastion (service_ec2.tfvars):
instance_type = "t2.micro"           # Smaller instance (-$9/month)
root_volume_size = 50                # Smaller volume (-$4/month)
enable_detailed_monitoring = false   # Disable detailed monitoring (-$2/month)
```

**Stop instances when not in use**:
```bash
# Stop RDS (saves ~$15/month when stopped)
aws rds stop-db-instance --db-instance-identifier cloudlens-metastore

# Stop bastion (saves ~$17/month when stopped)
aws ec2 stop-instances --instance-ids <bastion-instance-id>
```

**Production** (~$250/month):
```hcl
# RDS
instance_class = "db.r6g.large"      # Production-grade instance
multi_az = true                       # High availability
backup_retention_period = 30          # Extended backups
deletion_protection = true            # Prevent accidental deletion

# Bastion
instance_type = "t3.small"           # Better performance
# Consider Multi-AZ bastion hosts for HA
```

## 🔐 Security Checklist

### RDS Security
- ✅ Encryption at rest enabled (KMS)
- ✅ Credentials in Secrets Manager
- ✅ Not publicly accessible
- ✅ Security group restrictions
- ✅ Automated backups enabled
- ✅ Enhanced monitoring enabled

### Bastion Security
- ✅ SSH keys auto-generated and encrypted in SSM
- ✅ SSM Session Manager enabled (no SSH keys needed)
- ✅ IMDSv2 required
- ✅ Encrypted EBS volumes (KMS)
- ✅ Private subnet (no public IP)
- ✅ Minimal IAM permissions
- ✅ CloudWatch logging enabled
- ✅ Automatic security updates

## 📈 Next Steps

1. **Test connectivity** from bastion to RDS
2. **Set up CloudWatch alarms** for critical metrics (RDS and bastion)
3. **Test backup restoration** procedures
4. **Configure application** to use the database
5. **Set up port forwarding** for local database access
6. **Plan production deployment** with Multi-AZ (both RDS and bastion)
7. **Rotate SSH keys** periodically
8. **Review security group rules** and tighten access

## 🎯 Key Files to Know

```
cloudlens-databases/
├── QUICK_START.md                    ← You are here
├── README.md                         ← Project overview
├── DEPLOYMENT_SUMMARY.md             ← Complete summary
│
├── modules/
│   ├── rds/                          ← RDS module
│   │   ├── README.md                 ← Module documentation
│   │   └── examples.tf               ← Usage examples
│   │
│   └── ec2/                          ← Bastion module
│       ├── README.md                 ← Module documentation
│       ├── user_data.sh              ← Instance initialization
│       └── examples.tf               ← Usage examples
│
└── environments/dev/services/
    ├── rds/                          ← RDS deployment
    │   ├── README.md                 ← Deployment guide
    │   ├── DEPLOYMENT_CHECKLIST.md   ← Step-by-step checklist
    │   ├── validate.sh               ← Validation script
    │   └── service_rds.tfvars        ← Configuration ⚠️ UPDATE THIS
    │
    └── ec2/                          ← Bastion deployment
        ├── README.md                 ← Deployment guide
        ├── DEPLOYMENT_CHECKLIST.md   ← Step-by-step checklist
        ├── validate.sh               ← Validation script
        └── service_ec2.tfvars        ← Configuration ⚠️ UPDATE THIS
```

## ⚡ TL;DR

### RDS Only
```bash
cd environments/dev/services/rds
vim service_rds.tfvars  # Update vpc_id, subnet_ids, allowed_security_group_ids
./validate.sh && terraform init && terraform apply -var-file="service_rds.tfvars"
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .
```

### RDS + Bastion
```bash
# Deploy RDS first (see above)

# Deploy Bastion
cd environments/dev/services/ec2
vim service_ec2.tfvars  # Update vpc_id, subnet_id, kms_key_id, allowed_security_group_ids
./validate.sh && terraform init && terraform apply -var-file="service_ec2.tfvars"

# Connect to bastion
aws ssm start-session --target $(terraform output -raw instance_id)

# From bastion, connect to RDS
aws secretsmanager get-secret-value --secret-id <rds-secret-arn> --query SecretString --output text | jq .
psql -h <rds-endpoint> -U metastore_admin -d metastore
```

---

**Need more details?** See `DEPLOYMENT_SUMMARY.md` for the complete overview.

