# EC2 Bastion Host Deployment Checklist

Use this checklist to ensure a successful deployment of the EC2 bastion host.

## Pre-Deployment Checklist

### 1. AWS Prerequisites

- [ ] AWS CLI installed and configured
- [ ] AWS credentials have necessary permissions:
  - [ ] EC2 full access
  - [ ] VPC read access
  - [ ] Systems Manager (SSM) full access
  - [ ] KMS access for encryption/decryption
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
- [ ] Private subnet exists (recommended for bastion host)
- [ ] Subnet has appropriate routing (NAT gateway or VPC endpoints for internet access)
- [ ] Security groups for sources that need bastion access exist

**Verify VPC and Subnets:**
```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# List subnets in a VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-XXXXXXXX" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table
```

### 3. KMS Key Prerequisites

- [ ] KMS key exists for encryption
- [ ] KMS key policy allows EC2 and SSM to use the key
- [ ] Your IAM principal has permission to use the key

**Verify KMS Key:**
```bash
# List KMS keys
aws kms list-keys

# Describe specific key
aws kms describe-key --key-id <key-id>

# Check key policy
aws kms get-key-policy --key-id <key-id> --policy-name default
```

### 4. Configuration File Updates

- [ ] `service_ec2.tfvars` file updated with correct values:
  - [ ] `vpc_id` - Your VPC ID
  - [ ] `subnet_id` - Your private subnet ID
  - [ ] `kms_key_id` - Your KMS key ARN
  - [ ] `allowed_security_group_ids` or `allowed_cidr_blocks` - Sources that need SSH access
  - [ ] Review all other settings and adjust as needed

### 5. Cost Estimation

- [ ] Reviewed instance type and storage settings
- [ ] Estimated monthly cost is acceptable (~$28.50/month for default config)
- [ ] Budget alerts configured (if applicable)

**Estimate Cost:**
- t2.small instance: ~$17/month
- 100 GB gp3 storage: ~$8/month
- CloudWatch logs: ~$0.50/month
- Detailed monitoring: ~$2/month
- Data transfer: ~$1/month
- **Total**: ~$28.50/month (us-east-1)

### 6. Security Review

- [ ] SSH access is restricted to specific security groups or CIDR blocks
- [ ] Instance will be deployed in a private subnet (no public IP)
- [ ] KMS encryption is enabled for EBS volumes
- [ ] IMDSv2 is required (default: true)
- [ ] CloudWatch logging is enabled

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd environments/dev/services/ec2
terraform init
```

**Verify:**
- [ ] Terraform initialized successfully
- [ ] Required providers downloaded (aws, tls)
- [ ] No errors in output

### Step 2: Validate Configuration

```bash
terraform validate
```

**Verify:**
- [ ] Configuration is valid
- [ ] No syntax errors

### Step 3: Run Validation Script

```bash
./validate.sh
```

**Verify:**
- [ ] All checks passed
- [ ] VPC and subnet exist
- [ ] KMS key is accessible
- [ ] No critical errors

### Step 4: Plan Deployment

```bash
terraform plan -var-file="service_ec2.tfvars" -out=tfplan
```

**Review the plan and verify:**
- [ ] Correct number of resources will be created (~12-15 resources)
- [ ] VPC ID matches your VPC
- [ ] Subnet ID is correct
- [ ] KMS key ARN is correct
- [ ] Instance type is correct (t2.small)
- [ ] Storage settings are correct (100 GB gp3)
- [ ] Encryption is enabled
- [ ] No unexpected changes or deletions
- [ ] Tags are correct

**Expected Resources:**
- 1 x aws_instance
- 1 x tls_private_key
- 1 x aws_key_pair
- 1 x aws_ssm_parameter
- 1 x aws_security_group (if create_security_group = true)
- 2-3 x aws_security_group_rule
- 1 x aws_iam_role
- 1 x aws_iam_instance_profile
- 2-3 x aws_iam_role_policy_attachment
- 1 x aws_iam_policy

### Step 5: Apply Configuration

```bash
terraform apply tfplan
```

**Monitor:**
- [ ] Apply starts successfully
- [ ] Resources are being created
- [ ] No errors during creation

**Expected Duration:** 3-5 minutes

### Step 6: Verify Deployment

```bash
# Check outputs
terraform output

# Verify EC2 instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table
```

**Verify:**
- [ ] EC2 instance status is "running"
- [ ] Private IP address is displayed
- [ ] SSM parameter created
- [ ] Security group created (if applicable)
- [ ] All outputs are populated

## Post-Deployment Checklist

### 1. Verify SSH Key Storage

```bash
# Get SSM parameter name
SSM_PARAM=$(terraform output -raw ssm_parameter_name)

# Verify parameter exists
aws ssm describe-parameters --filters "Key=Name,Values=$SSM_PARAM"

# Verify parameter is encrypted
aws ssm get-parameter --name $SSM_PARAM --query 'Parameter.Type' --output text
```

**Verify:**
- [ ] SSM parameter exists
- [ ] Parameter type is "SecureString"
- [ ] Parameter is encrypted with the correct KMS key

### 2. Verify SSM Session Manager Access

```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw instance_id)

# Check SSM agent status
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
  --query 'InstanceInformationList[0].[InstanceId,PingStatus,PlatformName]' \
  --output table
```

**Verify:**
- [ ] Instance appears in SSM
- [ ] Ping status is "Online"
- [ ] Platform is "Amazon Linux"

### 3. Test SSM Session Manager Connection

```bash
# Start SSM session
aws ssm start-session --target $(terraform output -raw instance_id)
```

**Verify:**
- [ ] Session starts successfully
- [ ] You can execute commands
- [ ] Exit with `exit` command

### 4. Test SSH Connection (Optional)

```bash
# Retrieve private key
SSM_PARAM=$(terraform output -raw ssm_parameter_name)
aws ssm get-parameter --name $SSM_PARAM --with-decryption \
  --query Parameter.Value --output text > bastion-key.pem
chmod 400 bastion-key.pem

# Connect via SSH
PRIVATE_IP=$(terraform output -raw private_ip)
ssh -i bastion-key.pem ec2-user@$PRIVATE_IP

# Clean up
rm bastion-key.pem
```

**Verify:**
- [ ] Private key retrieved successfully
- [ ] SSH connection successful
- [ ] Can execute commands
- [ ] Private key deleted after use

### 5. Verify CloudWatch Monitoring

**CloudWatch Logs:**
```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/cloudlens-bastion-dev
```

**Verify:**
- [ ] Log groups exist
- [ ] Logs are being written

**CloudWatch Metrics:**
- [ ] Navigate to CloudWatch Console
- [ ] Select EC2 metrics
- [ ] Verify detailed monitoring metrics are visible

### 6. Verify Security Configuration

```bash
# Check security group rules
SG_ID=$(terraform output -raw security_group_id)
aws ec2 describe-security-groups --group-ids $SG_ID
```

**Verify:**
- [ ] Security group allows inbound SSH (port 22) from allowed sources
- [ ] Security group allows outbound HTTPS (port 443) for SSM
- [ ] No public access (0.0.0.0/0) unless intended

### 7. Verify IAM Configuration

```bash
# Check IAM role
ROLE_NAME=$(terraform output -raw iam_role_name)
aws iam get-role --role-name $ROLE_NAME

# List attached policies
aws iam list-attached-role-policies --role-name $ROLE_NAME
```

**Verify:**
- [ ] IAM role exists
- [ ] `AmazonSSMManagedInstanceCore` policy attached
- [ ] `CloudWatchAgentServerPolicy` policy attached (if enabled)
- [ ] Custom SSM parameter access policy attached

### 8. Test Database Connectivity

```bash
# Connect to bastion
aws ssm start-session --target $(terraform output -raw instance_id)

# Test PostgreSQL client
psql --version

# Test connectivity to RDS (if RDS is deployed)
# Replace with your RDS endpoint
# psql -h <rds-endpoint> -U <username> -d <database>
```

**Verify:**
- [ ] PostgreSQL client is installed
- [ ] Can connect to RDS instance (if deployed)

### 9. Document Deployment

- [ ] Record deployment date and time
- [ ] Document any issues encountered
- [ ] Update team documentation with connection details
- [ ] Share SSM parameter name with team (not the private key!)
- [ ] Update monitoring dashboards (if applicable)

## Troubleshooting

### Issue: Terraform plan fails with VPC not found

**Solution:**
- Verify VPC ID in `service_ec2.tfvars` is correct
- Ensure you're in the correct AWS region
- Check AWS credentials have VPC read permissions

### Issue: KMS key access denied

**Solution:**
- Verify KMS key ARN is correct
- Check KMS key policy allows EC2 and SSM services
- Ensure your IAM principal has `kms:Decrypt` and `kms:Encrypt` permissions

### Issue: Cannot connect via SSM Session Manager

**Solution:**
- Wait 5-10 minutes after instance launch for SSM agent to register
- Verify IAM instance profile is attached
- Check security group allows outbound HTTPS (port 443)
- Ensure subnet has route to internet (NAT gateway) or VPC endpoints for SSM

### Issue: Cannot retrieve private key from SSM

**Solution:**
- Check IAM permissions include `ssm:GetParameter`
- Verify KMS key policy allows decryption
- Ensure you're using `--with-decryption` flag

### Issue: SSH connection times out

**Solution:**
- Verify you're connecting from an allowed security group or CIDR block
- Check instance is running
- Ensure you're using the private IP (not public IP)
- Verify you're in the same VPC or have VPN/Direct Connect access

## Rollback Procedure

If deployment fails or needs to be rolled back:

```bash
# Destroy all resources
terraform destroy -var-file="service_ec2.tfvars"
```

**Note:** This will permanently delete:
- EC2 instance and EBS volume
- SSH key pair
- SSM parameter (private key)
- Security group
- IAM role and instance profile

## Next Steps

After successful deployment:

1. **Test RDS Connectivity**: Connect to RDS from bastion
2. **Set Up Monitoring Alarms**: Create CloudWatch alarms for critical metrics
3. **Document Procedures**: Update runbooks with operational procedures
4. **Configure Backup**: Consider AMI snapshots for disaster recovery
5. **Review Security**: Conduct security review of configuration
6. **Train Team**: Ensure team knows how to connect via SSM Session Manager

## Sign-Off

- [ ] Deployment completed successfully
- [ ] All verification steps passed
- [ ] Documentation updated
- [ ] Team notified

**Deployed by:** _______________  
**Date:** _______________  
**Environment:** Development  
**Instance Name:** cloudlens-bastion-dev

