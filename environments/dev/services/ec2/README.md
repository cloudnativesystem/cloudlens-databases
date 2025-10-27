# EC2 Bastion Host - Development Environment

This directory contains Terraform configuration for deploying an EC2 bastion host in the development environment for the CloudLens Databases project.

## Overview

The bastion host provides secure access to private database resources (RDS instances) within the VPC. It includes:

- **Automated SSH Key Management**: Generates and securely stores SSH keys in AWS Systems Manager Parameter Store
- **SSM Session Manager**: Enables secure shell access without SSH keys or public IPs
- **Database Tools**: Pre-installed PostgreSQL and MySQL clients
- **CloudWatch Monitoring**: Detailed monitoring and logging
- **Security Hardening**: IMDSv2, encrypted volumes, minimal IAM permissions

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- VPC with at least one private subnet
- KMS key for encryption (EBS volumes and SSM parameters)
- Security groups or CIDR blocks for SSH access control

## Configuration

### Required Configuration Updates

Before deploying, update the following values in `service_ec2.tfvars`:

1. **VPC ID**: Replace `vpc_id` with your actual VPC ID
2. **Subnet ID**: Replace `subnet_id` with your private subnet ID (same VPC as RDS)
3. **KMS Key ARN**: Replace `kms_key_id` with your KMS key ARN
4. **Allowed Access**: Update `allowed_security_group_ids` or `allowed_cidr_blocks` with sources that need SSH access

### Configuration File

The `service_ec2.tfvars` file contains all configuration values:

```hcl
name      = "cloudlens-bastion-dev"
vpc_id    = "vpc-xxxxxxxxxxxxxxxxx"  # UPDATE THIS
subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # UPDATE THIS
kms_key_id = "arn:aws:kms:..."  # UPDATE THIS

instance_type    = "t2.small"
root_volume_size = 100
root_volume_type = "gp3"

create_ssh_key    = true
ssh_key_algorithm = "RSA"
ssh_key_rsa_bits  = 4096

enable_detailed_monitoring = true
enable_cloudwatch_agent    = true
require_imdsv2             = true
```

## Deployment

### Step 1: Validate Configuration

Run the validation script to check prerequisites:

```bash
./validate.sh
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Plan Deployment

```bash
terraform plan -var-file="service_ec2.tfvars"
```

Review the plan to ensure:
- Correct VPC and subnet IDs
- KMS key ARN is valid
- Instance type and storage settings are correct
- Security group rules are appropriate

### Step 4: Deploy

```bash
terraform apply -var-file="service_ec2.tfvars"
```

Type `yes` when prompted. Deployment takes approximately 3-5 minutes.

### Step 5: Verify Deployment

```bash
# View outputs
terraform output

# Check instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)

# Verify SSM agent is running
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$(terraform output -raw instance_id)"
```

## Connecting to the Bastion Host

### Option 1: SSM Session Manager (Recommended)

No SSH key required, works from anywhere with AWS CLI:

```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw instance_id)

# Start SSM session
aws ssm start-session --target $INSTANCE_ID
```

**Advantages**:
- No SSH key management
- No public IP required
- Audit logging in CloudTrail
- Works from anywhere with AWS credentials

### Option 2: SSH (Requires Private Key)

```bash
# 1. Retrieve private key from SSM Parameter Store
SSM_PARAM=$(terraform output -raw ssm_parameter_name)
aws ssm get-parameter \
  --name $SSM_PARAM \
  --with-decryption \
  --query Parameter.Value \
  --output text > bastion-key.pem

# 2. Set correct permissions
chmod 400 bastion-key.pem

# 3. Get private IP
PRIVATE_IP=$(terraform output -raw private_ip)

# 4. Connect via SSH
ssh -i bastion-key.pem ec2-user@$PRIVATE_IP

# 5. IMPORTANT: Delete the key file after use
rm bastion-key.pem
```

**Security Note**: Never commit the private key to version control. Always delete it after use.

## Connecting to RDS from Bastion

### Method 1: Direct Connection from Bastion

```bash
# 1. Connect to bastion via SSM
aws ssm start-session --target $(terraform output -raw instance_id)

# 2. Retrieve RDS credentials from Secrets Manager
RDS_SECRET_ARN="<your-rds-secret-arn>"
aws secretsmanager get-secret-value \
  --secret-id $RDS_SECRET_ARN \
  --query SecretString \
  --output text | jq .

# 3. Connect to PostgreSQL
psql -h <rds-endpoint> -U <username> -d <database>
# Enter password when prompted
```

### Method 2: Port Forwarding via SSM

Forward RDS port to your local machine:

```bash
# Get instance ID and RDS endpoint
INSTANCE_ID=$(terraform output -raw instance_id)
RDS_ENDPOINT="<your-rds-endpoint>"

# Start port forwarding session
aws ssm start-session \
  --target $INSTANCE_ID \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"$RDS_ENDPOINT\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"5432\"]}"

# In another terminal, connect to localhost
psql -h localhost -U <username> -d <database>
```

## Outputs

After deployment, the following outputs are available:

```bash
# Instance information
terraform output instance_id
terraform output private_ip
terraform output instance_state

# Security information
terraform output security_group_id
terraform output key_pair_name

# SSM parameter information
terraform output ssm_parameter_name

# Connection commands
terraform output ssm_session_command
terraform output ssh_command

# Full instructions
terraform output instructions
```

## Monitoring

### CloudWatch Logs

Logs are sent to CloudWatch Logs:

```bash
# View system messages
aws logs tail /aws/ec2/cloudlens-bastion-dev/messages --follow

# View security logs
aws logs tail /aws/ec2/cloudlens-bastion-dev/secure --follow
```

### CloudWatch Metrics

View metrics in the CloudWatch console:
- CPU utilization
- Disk usage
- Memory usage
- Network throughput
- TCP connections

### Instance Status

```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)

# Check SSM agent status
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$(terraform output -raw instance_id)"
```

## Security

### Security Features

- ✅ **Encrypted EBS Volume**: Uses customer-managed KMS key
- ✅ **Secure Key Storage**: Private key stored in SSM Parameter Store as SecureString
- ✅ **IMDSv2 Required**: Enhanced instance metadata security
- ✅ **Private Subnet**: No public IP address
- ✅ **Security Group**: Restricted SSH access
- ✅ **IAM Role**: Minimal permissions (SSM, CloudWatch)
- ✅ **CloudWatch Logging**: Audit trail of all activities

### Security Best Practices

1. **Use SSM Session Manager** instead of SSH when possible
2. **Never commit private keys** to version control
3. **Rotate SSH keys** periodically by recreating the module
4. **Restrict security group access** to specific sources
5. **Monitor CloudWatch logs** for suspicious activity
6. **Enable MFA** for AWS console and CLI access
7. **Use least privilege IAM policies**
8. **Keep the instance updated** (automatic security updates enabled)

## Maintenance

### Updating the Instance

```bash
# Connect via SSM
aws ssm start-session --target $(terraform output -raw instance_id)

# Update packages
sudo dnf update -y

# Reboot if kernel was updated
sudo reboot
```

### Rotating SSH Keys

To rotate SSH keys, simply redeploy:

```bash
# This will generate a new key pair and update SSM Parameter Store
terraform apply -var-file="service_ec2.tfvars"
```

### Stopping/Starting the Instance

```bash
# Stop instance (to save costs when not in use)
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)

# Start instance
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)
```

## Troubleshooting

### Cannot connect via SSM Session Manager

**Symptoms**: `aws ssm start-session` fails with "TargetNotConnected"

**Solutions**:
1. Verify SSM agent is running:
   ```bash
   aws ssm describe-instance-information --filters "Key=InstanceIds,Values=<instance-id>"
   ```
2. Check IAM instance profile has `AmazonSSMManagedInstanceCore` policy
3. Ensure instance can reach SSM endpoints (check VPC endpoints or NAT gateway)
4. Verify security group allows outbound HTTPS (port 443)

### Cannot retrieve private key from SSM

**Symptoms**: `aws ssm get-parameter` fails with "AccessDenied"

**Solutions**:
1. Check IAM permissions include `ssm:GetParameter` and `kms:Decrypt`
2. Verify KMS key policy allows your IAM principal to decrypt
3. Ensure you're using `--with-decryption` flag

### SSH connection refused

**Symptoms**: `ssh` command times out or connection refused

**Solutions**:
1. Verify security group allows inbound SSH (port 22) from your source
2. Check instance is running: `aws ec2 describe-instances`
3. Ensure you're using the correct private key
4. Verify you're connecting from an allowed security group or CIDR block
5. Check you're using the private IP (not public IP for private subnet)

### Instance not appearing in SSM

**Symptoms**: Instance doesn't show up in Systems Manager

**Solutions**:
1. Wait 5-10 minutes after instance launch
2. Check SSM agent is installed and running (should be on AL2023)
3. Verify IAM instance profile is attached
4. Check VPC has route to SSM endpoints

## Cost Estimation

### Monthly Cost (us-east-1)

- **EC2 Instance** (t2.small): ~$17/month
- **EBS Volume** (100 GB gp3): ~$8/month
- **CloudWatch Logs**: ~$0.50/month
- **Detailed Monitoring**: ~$2/month
- **SSM Parameter Store**: Free
- **Data Transfer**: ~$1/month
- **Total**: ~$28.50/month

### Cost Optimization

- **Stop when not in use**: Stop the instance during off-hours
- **Use smaller instance**: t2.micro (~$8.50/month) for light usage
- **Reduce volume size**: 50 GB instead of 100 GB (~$4/month savings)
- **Disable detailed monitoring**: Save ~$2/month (not recommended for production)

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="service_ec2.tfvars"
```

**Warning**: This will permanently delete:
- EC2 instance
- EBS volume
- SSH key pair
- SSM parameter (private key)
- Security group
- IAM role and instance profile

## Support

For questions or issues:
- Review module documentation: `../../../../modules/ec2/README.md`
- Check deployment checklist: `DEPLOYMENT_CHECKLIST.md`
- Contact the CloudLens platform team

## Related Resources

- **RDS Instance**: `../rds/` - PostgreSQL RDS instance for Hive Metastore
- **Module Documentation**: `../../../../modules/ec2/README.md`
- **Root README**: `../../../../README.md`

