# EC2 Bastion Host Terraform Module

A comprehensive, production-ready Terraform module for deploying EC2 bastion hosts with automated SSH key management, secure key storage in AWS Systems Manager Parameter Store, and SSM Session Manager access.

## Features

- ✅ **Automated SSH Key Generation**: Generates X.509 RSA/ECDSA/ED25519 key pairs using Terraform
- ✅ **Secure Key Storage**: Stores private keys in AWS Systems Manager Parameter Store as SecureString
- ✅ **KMS Encryption**: Encrypts EBS volumes and SSM parameters with customer-managed KMS keys
- ✅ **SSM Session Manager**: Enables secure shell access without SSH keys or bastion public IPs
- ✅ **CloudWatch Integration**: Optional CloudWatch Agent for logs and metrics
- ✅ **Security Hardening**: IMDSv2 enforcement, encrypted volumes, minimal IAM permissions
- ✅ **Flexible Networking**: Create new or use existing security groups
- ✅ **Elastic IP Support**: Optional EIP allocation for static public IP
- ✅ **Amazon Linux 2023**: Uses latest AL2023 AMI by default (configurable)
- ✅ **Database Tools**: Pre-installed PostgreSQL and MySQL clients for database access

## Usage

### Basic Example

```hcl
module "bastion" {
  source = "../../modules/ec2"

  name      = "cloudlens-bastion"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-12345678"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  instance_type = "t2.small"
  root_volume_size = 100

  allowed_security_group_ids = ["sg-12345678"]

  tags = {
    Environment = "dev"
    Project     = "cloudlens"
  }
}
```

### Production Example with All Features

```hcl
module "bastion_prod" {
  source = "../../modules/ec2"

  name      = "cloudlens-bastion-prod"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-12345678"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Instance configuration
  instance_type = "t3.small"
  ami_id        = null  # Use latest Amazon Linux 2023

  # Storage configuration
  root_volume_type      = "gp3"
  root_volume_size      = 100
  root_volume_encrypted = true

  # Network configuration
  create_security_group      = true
  allowed_security_group_ids = ["sg-app-servers"]
  allowed_cidr_blocks        = ["10.0.0.0/8"]
  allocate_eip               = false  # Private subnet, no public IP

  # SSH key configuration
  create_ssh_key     = true
  ssh_key_algorithm  = "RSA"
  ssh_key_rsa_bits   = 4096
  ssm_parameter_name = "/cloudlens/bastion/ssh-private-key"

  # IAM configuration
  additional_iam_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  # Monitoring
  enable_detailed_monitoring = true
  enable_cloudwatch_agent    = true

  # Security
  require_imdsv2 = true

  tags = {
    Environment = "production"
    Project     = "cloudlens"
    Owner       = "platform-team"
    ManagedBy   = "Terraform"
  }
}
```

### Using Existing Security Group and Key Pair

```hcl
module "bastion_custom" {
  source = "../../modules/ec2"

  name      = "cloudlens-bastion-custom"
  vpc_id    = "vpc-12345678"
  subnet_id = "subnet-12345678"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Use existing security group
  create_security_group = false
  security_group_ids    = ["sg-existing-12345678"]

  # Use existing key pair
  create_ssh_key         = false
  existing_key_pair_name = "my-existing-key"

  instance_type    = "t2.small"
  root_volume_size = 50

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
| tls | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| tls | >= 4.0 |

## Resources Created

- `aws_instance` - EC2 bastion host instance
- `tls_private_key` - SSH private key (if create_ssh_key = true)
- `aws_key_pair` - EC2 key pair (if create_ssh_key = true)
- `aws_ssm_parameter` - SSM parameter for private key storage (if create_ssh_key = true)
- `aws_security_group` - Security group (if create_security_group = true)
- `aws_security_group_rule` - Security group rules (if create_security_group = true)
- `aws_iam_role` - IAM role for instance
- `aws_iam_instance_profile` - IAM instance profile
- `aws_iam_role_policy_attachment` - IAM policy attachments
- `aws_iam_policy` - Custom IAM policy for SSM parameter access
- `aws_eip` - Elastic IP (if allocate_eip = true)
- `aws_eip_association` - EIP association (if allocate_eip = true)

## Inputs

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name | Name of the bastion host | `string` | - |
| vpc_id | ID of the VPC | `string` | - |
| subnet_id | ID of the subnet | `string` | - |
| kms_key_id | ARN of the KMS key for encryption | `string` | - |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| instance_type | EC2 instance type | `string` | `"t2.small"` |
| ami_id | AMI ID (null for latest AL2023) | `string` | `null` |
| root_volume_type | Root volume type | `string` | `"gp3"` |
| root_volume_size | Root volume size in GB | `number` | `100` |
| root_volume_encrypted | Encrypt root volume | `bool` | `true` |
| create_security_group | Create security group | `bool` | `true` |
| security_group_ids | Existing security group IDs | `list(string)` | `[]` |
| allowed_security_group_ids | Allowed security group IDs for SSH | `list(string)` | `[]` |
| allowed_cidr_blocks | Allowed CIDR blocks for SSH | `list(string)` | `[]` |
| allocate_eip | Allocate Elastic IP | `bool` | `false` |
| create_ssh_key | Create new SSH key pair | `bool` | `true` |
| existing_key_pair_name | Existing key pair name | `string` | `null` |
| ssh_key_algorithm | SSH key algorithm | `string` | `"RSA"` |
| ssh_key_rsa_bits | RSA key bits | `number` | `4096` |
| ssm_parameter_name | SSM parameter name for private key | `string` | `null` |
| additional_iam_policy_arns | Additional IAM policy ARNs | `list(string)` | `[]` |
| enable_detailed_monitoring | Enable detailed monitoring | `bool` | `true` |
| enable_cloudwatch_agent | Enable CloudWatch Agent | `bool` | `true` |
| require_imdsv2 | Require IMDSv2 | `bool` | `true` |
| user_data | Custom user data script | `string` | `null` |
| tags | Tags to apply to resources | `map(string)` | `{}` |

See [variables.tf](variables.tf) for complete list and validation rules.

## Outputs

| Name | Description |
|------|-------------|
| instance_id | ID of the EC2 instance |
| instance_arn | ARN of the EC2 instance |
| private_ip | Private IP address |
| public_ip | Public IP address (if allocated) |
| security_group_id | Security group ID (if created) |
| key_pair_name | EC2 key pair name |
| ssm_parameter_name | SSM parameter name for private key |
| ssm_parameter_arn | SSM parameter ARN (sensitive) |
| iam_role_arn | IAM role ARN |
| iam_instance_profile_arn | IAM instance profile ARN |
| ssh_command | SSH command to connect |
| ssm_session_command | SSM session command |
| retrieve_private_key_command | Command to retrieve private key (sensitive) |
| instructions | Connection instructions |

See [outputs.tf](outputs.tf) for complete list.

## Connecting to the Bastion Host

### Option 1: SSM Session Manager (Recommended)

No SSH key required, works from anywhere with AWS CLI:

```bash
# Start SSM session
aws ssm start-session --target <instance-id>

# Port forwarding example (for RDS access)
aws ssm start-session \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

### Option 2: SSH (Requires Private Key)

```bash
# 1. Retrieve private key from SSM Parameter Store
aws ssm get-parameter \
  --name <ssm-parameter-name> \
  --with-decryption \
  --query Parameter.Value \
  --output text > bastion-key.pem

# 2. Set correct permissions
chmod 400 bastion-key.pem

# 3. Connect via SSH
ssh -i bastion-key.pem ec2-user@<private-ip>

# 4. IMPORTANT: Delete the key file after use
rm bastion-key.pem
```

## Connecting to RDS from Bastion

```bash
# 1. Connect to bastion via SSM
aws ssm start-session --target <instance-id>

# 2. Retrieve RDS credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id <rds-secret-arn> \
  --query SecretString \
  --output text | jq .

# 3. Connect to PostgreSQL
psql -h <rds-endpoint> -U <username> -d <database>
```

## Security Best Practices

1. **Use SSM Session Manager** instead of SSH when possible (no key management needed)
2. **Never commit private keys** to version control (they're stored in SSM Parameter Store)
3. **Use customer-managed KMS keys** for encryption
4. **Enable IMDSv2** (enabled by default in this module)
5. **Deploy in private subnets** (no public IP unless required)
6. **Restrict security group access** to specific security groups or CIDR blocks
7. **Enable CloudWatch Agent** for logging and monitoring
8. **Rotate SSH keys** periodically by recreating the module
9. **Use least privilege IAM policies** (only attach necessary policies)
10. **Enable detailed monitoring** for production instances

## Troubleshooting

### Cannot connect via SSM Session Manager

- Verify SSM agent is running: `systemctl status amazon-ssm-agent`
- Check IAM instance profile has `AmazonSSMManagedInstanceCore` policy
- Ensure instance can reach SSM endpoints (check VPC endpoints or NAT gateway)
- Verify security group allows outbound HTTPS (port 443)

### Cannot retrieve private key from SSM

- Check IAM permissions include `ssm:GetParameter` and `kms:Decrypt`
- Verify KMS key policy allows the IAM principal to decrypt
- Ensure SSM parameter exists: `aws ssm describe-parameters`

### SSH connection refused

- Verify security group allows inbound SSH (port 22) from your source
- Check instance is running: `aws ec2 describe-instances`
- Ensure you're using the correct private key
- Verify you're connecting from an allowed security group or CIDR block

## Cost Estimation

### Development Configuration
- **Instance** (t2.small): ~$17/month
- **EBS Volume** (100 GB gp3): ~$8/month
- **CloudWatch Logs**: ~$0.50/month
- **SSM Parameter Store**: Free
- **Total**: ~$25.50/month

### Production Configuration
- **Instance** (t3.small): ~$15/month
- **EBS Volume** (100 GB gp3): ~$8/month
- **CloudWatch Logs**: ~$1/month
- **Detailed Monitoring**: ~$2/month
- **Total**: ~$26/month

## License

Maintained by the CloudLens team.

