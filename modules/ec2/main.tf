# main.tf
# Reusable EC2 Bastion Host Module for CloudLens Databases

# ===========================
# Data Sources
# ===========================

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ===========================
# SSH Key Pair Generation
# ===========================

# Generate TLS private key for SSH access
resource "tls_private_key" "bastion" {
  count = var.create_ssh_key ? 1 : 0

  algorithm = var.ssh_key_algorithm
  rsa_bits  = var.ssh_key_algorithm == "RSA" ? var.ssh_key_rsa_bits : null
}

# Create AWS EC2 Key Pair from generated public key
resource "aws_key_pair" "bastion" {
  count = var.create_ssh_key ? 1 : 0

  key_name_prefix = "${var.name}-"
  public_key      = tls_private_key.bastion[0].public_key_openssh

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-key-pair"
    }
  )
}

# Store private key in SSM Parameter Store as SecureString
resource "aws_ssm_parameter" "private_key" {
  count = var.create_ssh_key ? 1 : 0

  name        = var.ssm_parameter_name != null ? var.ssm_parameter_name : "/${var.name}/ssh-private-key"
  description = "SSH private key for ${var.name} bastion host"
  type        = "SecureString"
  value       = tls_private_key.bastion[0].private_key_pem
  key_id      = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ssh-private-key"
    }
  )
}

# ===========================
# Security Group
# ===========================

# Security Group for bastion host
resource "aws_security_group" "bastion" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${var.name}-"
  description = "Security group for ${var.name} bastion host"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# SSH ingress from allowed security groups
resource "aws_security_group_rule" "ssh_ingress_sg" {
  count = var.create_security_group && length(var.allowed_security_group_ids) > 0 ? length(var.allowed_security_group_ids) : 0

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.bastion[0].id
  description              = "Allow SSH access from security group ${var.allowed_security_group_ids[count.index]}"
}

# SSH ingress from allowed CIDR blocks
resource "aws_security_group_rule" "ssh_ingress_cidr" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH access from CIDR blocks"
}

# Egress rule - allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow all outbound traffic"
}

# ===========================
# IAM Role and Instance Profile
# ===========================

# IAM role for EC2 instance
resource "aws_iam_role" "bastion" {
  name_prefix        = "${var.name}-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-role"
    }
  )
}

# IAM assume role policy for EC2
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Attach AWS managed policy for SSM Session Manager
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AWS managed policy for CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enable_cloudwatch_agent ? 1 : 0

  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom IAM policy for SSM parameter access (to retrieve private key if needed)
resource "aws_iam_policy" "ssm_parameter_access" {
  count = var.create_ssh_key ? 1 : 0

  name_prefix = "${var.name}-ssm-access-"
  description = "Allow access to SSM parameter for ${var.name} SSH private key"
  policy      = data.aws_iam_policy_document.ssm_parameter_access[0].json

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-ssm-access-policy"
    }
  )
}

data "aws_iam_policy_document" "ssm_parameter_access" {
  count = var.create_ssh_key ? 1 : 0

  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]

    resources = [
      aws_ssm_parameter.private_key[0].arn
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
    ]

    resources = [
      var.kms_key_id
    ]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.name}.amazonaws.com"]
    }
  }
}

# Attach custom SSM parameter access policy
resource "aws_iam_role_policy_attachment" "ssm_parameter_access" {
  count = var.create_ssh_key ? 1 : 0

  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.ssm_parameter_access[0].arn
}

# Attach additional custom policies if provided
resource "aws_iam_role_policy_attachment" "custom" {
  count = length(var.additional_iam_policy_arns)

  role       = aws_iam_role.bastion.name
  policy_arn = var.additional_iam_policy_arns[count.index]
}

# IAM instance profile
resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "${var.name}-"
  role        = aws_iam_role.bastion.name

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-instance-profile"
    }
  )
}

# Get current AWS region
data "aws_region" "current" {}

# ===========================
# EC2 Instance
# ===========================

# EC2 bastion host instance
resource "aws_instance" "bastion" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id
  instance_type = var.instance_type
  key_name      = var.create_ssh_key ? aws_key_pair.bastion[0].key_name : var.existing_key_pair_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.bastion[0].id] : var.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  # EBS root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_encrypted ? var.kms_key_id : null
    delete_on_termination = var.root_volume_delete_on_termination

    tags = merge(
      var.tags,
      {
        Name = "${var.name}-root-volume"
      }
    )
  }

  # Enable detailed monitoring
  monitoring = var.enable_detailed_monitoring

  # User data script for initial configuration
  user_data = var.user_data != null ? var.user_data : templatefile("${path.module}/user_data.sh", {
    cloudwatch_agent_enabled = var.enable_cloudwatch_agent
    hostname                 = var.name
  })

  # Metadata options for IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Disable source/destination check if needed (for NAT instances)
  source_dest_check = var.source_dest_check

  # Tags
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  # Volume tags
  volume_tags = merge(
    var.tags,
    {
      Name = "${var.name}-volume"
    }
  )

  # Lifecycle
  lifecycle {
    ignore_changes = [
      ami,
      user_data,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_managed_instance_core,
  ]
}

# ===========================
# Elastic IP (Optional)
# ===========================

# Allocate Elastic IP if requested
resource "aws_eip" "bastion" {
  count = var.allocate_eip ? 1 : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eip"
    }
  )
}

# Associate Elastic IP with instance
resource "aws_eip_association" "bastion" {
  count = var.allocate_eip ? 1 : 0

  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion[0].id
}
