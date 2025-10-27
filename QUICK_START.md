# Quick Start Guide - RDS PostgreSQL for Hive Metastore

## 🚀 Deploy in 5 Minutes

### Prerequisites
- ✅ Terraform >= 1.5.0
- ✅ AWS CLI configured
- ✅ VPC with 2+ subnets in different AZs

### Step 1: Update Configuration (2 minutes)

```bash
cd environments/dev/services/rds
```

Edit `service_rds.tfvars` and replace these 3 values:

```hcl
# 1. Your VPC ID
vpc_id = "vpc-YOUR_VPC_ID_HERE"

# 2. Your subnet IDs (minimum 2, different AZs)
subnet_ids = [
  "subnet-YOUR_SUBNET_1_HERE",
  "subnet-YOUR_SUBNET_2_HERE"
]

# 3. Security groups that need database access
allowed_security_group_ids = [
  "sg-YOUR_EC2_SECURITY_GROUP_HERE"
]
```

### Step 2: Validate (30 seconds)

```bash
./validate.sh
```

### Step 3: Deploy (2 minutes)

```bash
terraform init
terraform plan -var-file="service_rds.tfvars"
terraform apply -var-file="service_rds.tfvars"
```

Type `yes` when prompted.

⏱️ **Wait 10-15 minutes** for RDS instance to be created.

### Step 4: Get Credentials (30 seconds)

```bash
# Get the secret ARN
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)

# Retrieve credentials
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq .
```

## 📋 What You Get

- **Database**: PostgreSQL 15.4
- **Instance**: db.t3.micro (suitable for dev)
- **Storage**: 20 GB (auto-scales to 100 GB)
- **Encryption**: ✅ Enabled
- **Backups**: ✅ 7 days retention
- **Monitoring**: ✅ Enhanced monitoring + CloudWatch logs
- **Cost**: ~$21/month

## 🔌 Connect to Database

### From EC2 Instance (in same VPC)

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

### Connection String Format

```
postgresql://metastore_admin:<password>@<host>:5432/metastore
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

### Terraform errors
- ✅ Run `./validate.sh` to check configuration
- ✅ Verify VPC and subnet IDs are correct
- ✅ Ensure subnets are in different AZs

### Need help?
- Check `environments/dev/services/rds/README.md` for detailed troubleshooting
- Review AWS RDS documentation
- Contact CloudLens platform team

## 💰 Cost Optimization

**Development** (~$21/month):
- Current configuration is already optimized for dev

**To reduce costs further**:
```hcl
# In service_rds.tfvars:
monitoring_interval = 0              # Disable enhanced monitoring (-$1.50/month)
enabled_cloudwatch_logs_exports = [] # Disable log exports (-$0.50/month)
backup_retention_period = 1          # Minimal backups (-$1/month)
```

**Production** (~$223/month):
```hcl
instance_class = "db.r6g.large"      # Production-grade instance
multi_az = true                       # High availability
backup_retention_period = 30          # Extended backups
deletion_protection = true            # Prevent accidental deletion
```

## 🔐 Security Checklist

- ✅ Encryption at rest enabled
- ✅ Credentials in Secrets Manager
- ✅ Not publicly accessible
- ✅ Security group restrictions
- ✅ Automated backups enabled
- ✅ Enhanced monitoring enabled

## 📈 Next Steps

1. **Test connectivity** from your application
2. **Set up CloudWatch alarms** for critical metrics
3. **Test backup restoration** procedures
4. **Configure application** to use the database
5. **Plan production deployment** with Multi-AZ

## 🎯 Key Files to Know

```
cloudlens-databases/
├── QUICK_START.md                    ← You are here
├── README.md                         ← Project overview
├── DEPLOYMENT_SUMMARY.md             ← Complete summary
│
├── modules/rds/                      ← Reusable module
│   ├── README.md                     ← Module documentation
│   └── examples.tf                   ← Usage examples
│
└── environments/dev/services/rds/    ← Dev environment
    ├── README.md                     ← Deployment guide
    ├── DEPLOYMENT_CHECKLIST.md       ← Step-by-step checklist
    ├── validate.sh                   ← Validation script
    └── service_rds.tfvars            ← Configuration file ⚠️ UPDATE THIS
```

## ⚡ TL;DR

```bash
# 1. Update configuration
cd environments/dev/services/rds
vim service_rds.tfvars  # Update vpc_id, subnet_ids, allowed_security_group_ids

# 2. Deploy
./validate.sh
terraform init
terraform apply -var-file="service_rds.tfvars"

# 3. Get credentials
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)
aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq .

# 4. Connect
PGPASSWORD=<password> psql -h <host> -U metastore_admin -d metastore
```

---

**Need more details?** See `DEPLOYMENT_SUMMARY.md` for the complete overview.

