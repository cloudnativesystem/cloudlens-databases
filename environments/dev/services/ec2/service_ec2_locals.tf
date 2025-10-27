# service_ec2_locals.tf
# Local values for EC2 Bastion Host - Development Environment

locals {
  tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      Name        = var.name
      ManagedBy   = "Terraform"
      Purpose     = "Bastion Host for Database Access"
    },
    var.additional_tags
  )
}
