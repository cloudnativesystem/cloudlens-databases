# service_ec2_main.tf
# EC2 Bastion Host for CloudLens Databases - Development Environment

module "cloudlens_bastion" {
  source = "../../../../modules/ec2"

  # Instance identification
  name = var.name

  # Network configuration
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  # Instance configuration
  instance_type = var.instance_type
  ami_id        = var.ami_id

  # Storage configuration
  root_volume_type                  = var.root_volume_type
  root_volume_size                  = var.root_volume_size
  root_volume_encrypted             = var.root_volume_encrypted
  root_volume_delete_on_termination = var.root_volume_delete_on_termination

  # KMS encryption
  kms_key_id = var.kms_key_id

  # Security group configuration
  create_security_group      = var.create_security_group
  security_group_ids         = var.security_group_ids
  allowed_security_group_ids = var.allowed_security_group_ids
  allowed_cidr_blocks        = var.allowed_cidr_blocks

  # Elastic IP configuration
  allocate_eip = var.allocate_eip

  # Source/destination check
  source_dest_check = var.source_dest_check

  # SSH key configuration
  create_ssh_key         = var.create_ssh_key
  existing_key_pair_name = var.existing_key_pair_name
  ssh_key_algorithm      = var.ssh_key_algorithm
  ssh_key_rsa_bits       = var.ssh_key_rsa_bits
  ssm_parameter_name     = var.ssm_parameter_name

  # IAM configuration
  additional_iam_policy_arns = var.additional_iam_policy_arns

  # Monitoring and logging
  enable_detailed_monitoring = var.enable_detailed_monitoring
  enable_cloudwatch_agent    = var.enable_cloudwatch_agent

  # Security configuration
  require_imdsv2 = var.require_imdsv2

  # User data
  user_data = var.user_data

  # Tags
  tags = local.tags
}
