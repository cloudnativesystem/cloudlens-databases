# RDS Deployment Checklist

Use this checklist to ensure a successful deployment of the RDS PostgreSQL instance.

## Pre-Deployment Checklist

### 1. AWS Prerequisites

- [ ] AWS CLI installed and configured
- [ ] AWS credentials have necessary permissions:
  - [ ] RDS full access
  - [ ] VPC read access
  - [ ] Secrets Manager full access
  - [ ] KMS access (if using custom keys)
  - [ ] IAM role creation permissions
  - [ ] CloudWatch Logs access
- [ ] Terraform version >= 1.5.0 installed
- [ ] Verify you're in the correct AWS account and region

```bash
aws sts get-caller-identity
aws configure get region
```

### 2. Network Prerequisites

- [ ] VPC exists and is properly configured
- [ ] At least 2 subnets exist in different availability zones
- [ ] Subnets have appropriate routing (private subnets recommended)
- [ ] Security groups for EC2 instances that need database access exist

**Verify VPC and Subnets:**
```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# List subnets in a VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-XXXXXXXX" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' --output table
```

### 3. Configuration File Updates

- [ ] `service_rds.tfvars` file updated with correct values:
  - [ ] `vpc_id` - Your VPC ID
  - [ ] `subnet_ids` - At least 2 subnet IDs in different AZs
  - [ ] `allowed_security_group_ids` - Security groups that need access
  - [ ] `identifier` - Unique database identifier
  - [ ] Review all other settings and adjust as needed

### 4. Cost Estimation

- [ ] Reviewed instance class and storage settings
- [ ] Estimated monthly cost is acceptable
- [ ] Budget alerts configured (if applicable)

**Estimate Cost:**
- db.t3.micro: ~$15/month
- 20 GB gp3 storage: ~$2.50/month
- Backup storage (7 days): ~$2/month
- Enhanced monitoring: ~$1.50/month
- **Total**: ~$21/month (us-east-1)

### 5. Backup and Recovery Plan

- [ ] Backup retention period is appropriate (7 days for dev)
- [ ] Backup window doesn't conflict with peak usage
- [ ] Maintenance window is acceptable
- [ ] Recovery procedures documented

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd environments/dev/services/rds
terraform init
```

**Verify:**
- [ ] Terraform initialized successfully
- [ ] Required providers downloaded
- [ ] No errors in output

### Step 2: Validate Configuration

```bash
terraform validate
```

**Verify:**
- [ ] Configuration is valid
- [ ] No syntax errors

### Step 3: Plan Deployment

```bash
terraform plan -var-file="service_rds.tfvars" -out=tfplan
```

**Review the plan and verify:**
- [ ] Correct number of resources will be created (~10-15 resources)
- [ ] VPC ID matches your VPC
- [ ] Subnet IDs are correct
- [ ] Instance class is correct (db.t3.micro)
- [ ] Storage settings are correct (20 GB)
- [ ] Encryption is enabled
- [ ] No unexpected changes or deletions
- [ ] Tags are correct

**Expected Resources:**
- 1 x aws_db_instance
- 1 x aws_db_subnet_group
- 1 x aws_db_parameter_group
- 1 x aws_security_group
- 3-4 x aws_security_group_rule
- 1 x aws_secretsmanager_secret
- 1 x aws_secretsmanager_secret_version
- 1 x aws_iam_role
- 1 x aws_iam_role_policy_attachment
- 1 x random_password

### Step 4: Apply Configuration

```bash
terraform apply tfplan
```

**Monitor:**
- [ ] Apply starts successfully
- [ ] Resources are being created
- [ ] No errors during creation

**Expected Duration:** 10-15 minutes

### Step 5: Verify Deployment

```bash
# Check outputs
terraform output

# Verify RDS instance status
aws rds describe-db-instances --db-instance-identifier cloudlens-metastore \
  --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table
```

**Verify:**
- [ ] RDS instance status is "available"
- [ ] Endpoint address is displayed
- [ ] Secrets Manager secret created
- [ ] Security group created
- [ ] All outputs are populated

## Post-Deployment Checklist

### 1. Verify Database Credentials

```bash
# Get secret ARN
SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)

# Retrieve credentials
aws secretsmanager get-secret-value --secret-id $SECRET_ARN \
  --query SecretString --output text | jq .
```

**Verify:**
- [ ] Secret contains username
- [ ] Secret contains password
- [ ] Secret contains host
- [ ] Secret contains port
- [ ] Secret contains dbname

### 2. Test Database Connectivity

From an EC2 instance in the same VPC:

```bash
# Install PostgreSQL client
sudo yum install postgresql15 -y

# Get connection details
HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .host)
PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN \
  --query SecretString --output text | jq -r .password)

# Test connection
PGPASSWORD=$PASSWORD psql -h $HOST -U metastore_admin -d metastore -c "SELECT version();"
```

**Verify:**
- [ ] Connection successful
- [ ] PostgreSQL version displayed
- [ ] Can execute queries

### 3. Verify Monitoring

**CloudWatch Logs:**
```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /aws/rds/instance/cloudlens-metastore
```

**Verify:**
- [ ] Log group exists
- [ ] Logs are being written

**Enhanced Monitoring:**
- [ ] Navigate to RDS Console
- [ ] Select the instance
- [ ] Check "Monitoring" tab
- [ ] Verify enhanced monitoring metrics are visible

### 4. Verify Backup Configuration

```bash
aws rds describe-db-instances --db-instance-identifier cloudlens-metastore \
  --query 'DBInstances[0].[BackupRetentionPeriod,PreferredBackupWindow,PreferredMaintenanceWindow]' \
  --output table
```

**Verify:**
- [ ] Backup retention period is 7 days
- [ ] Backup window is 03:00-04:00
- [ ] Maintenance window is mon:04:00-mon:05:00

### 5. Verify Security Configuration

```bash
# Check security group rules
SG_ID=$(terraform output -raw security_group_id)
aws ec2 describe-security-groups --group-ids $SG_ID
```

**Verify:**
- [ ] Security group allows inbound on port 5432
- [ ] Inbound rules match expected security groups/CIDR blocks
- [ ] No public access (0.0.0.0/0) unless intended

### 6. Verify Encryption

```bash
aws rds describe-db-instances --db-instance-identifier cloudlens-metastore \
  --query 'DBInstances[0].[StorageEncrypted,KmsKeyId]' \
  --output table
```

**Verify:**
- [ ] Storage encryption is enabled
- [ ] KMS key ID is displayed

### 7. Document Deployment

- [ ] Record deployment date and time
- [ ] Document any issues encountered
- [ ] Update team documentation with connection details
- [ ] Share Secrets Manager secret ARN with team (not the password!)
- [ ] Update monitoring dashboards (if applicable)

## Troubleshooting

### Issue: Terraform plan fails with VPC not found

**Solution:**
- Verify VPC ID in `service_rds.tfvars` is correct
- Ensure you're in the correct AWS region
- Check AWS credentials have VPC read permissions

### Issue: Subnet IDs must be in different availability zones

**Solution:**
- Verify subnet IDs are in different AZs
- Use `aws ec2 describe-subnets` to check AZs
- Update `subnet_ids` in `service_rds.tfvars`

### Issue: Cannot connect to database

**Solution:**
- Verify security group allows inbound traffic from your source
- Check that source security group is in `allowed_security_group_ids`
- Ensure database status is "available"
- Verify you're connecting from within the VPC

### Issue: Secrets Manager secret not found

**Solution:**
- Wait for Terraform apply to complete fully
- Check Secrets Manager console for the secret
- Verify secret ARN from Terraform outputs

## Rollback Procedure

If deployment fails or needs to be rolled back:

```bash
# Destroy all resources
terraform destroy -var-file="service_rds.tfvars"
```

**Note:** This will permanently delete the database. Ensure you have backups if needed.

## Next Steps

After successful deployment:

1. **Configure Application**: Update application configuration with database endpoint
2. **Set Up Monitoring Alarms**: Create CloudWatch alarms for critical metrics
3. **Test Backup Restoration**: Verify backup and restore procedures
4. **Document Procedures**: Update runbooks with operational procedures
5. **Schedule Maintenance**: Plan for future maintenance windows
6. **Review Security**: Conduct security review of configuration

## Sign-Off

- [ ] Deployment completed successfully
- [ ] All verification steps passed
- [ ] Documentation updated
- [ ] Team notified

**Deployed by:** _______________  
**Date:** _______________  
**Environment:** Development  
**Database Identifier:** cloudlens-metastore

