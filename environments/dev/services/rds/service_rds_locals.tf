# service_rds_locals.tf
# Local values for the development RDS instance

locals {
  # Merge all tags together
  tags = merge(
    {
      Environment = var.environment
      Project     = var.project
      Owner       = var.owner
      Name        = var.identifier
      ManagedBy   = "Terraform"
      Purpose     = "Hive Metastore Database"
    },
    var.additional_tags
  )
}
