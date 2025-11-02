terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Credentials are provided by the environment or CI (GitHub Actions OIDC / secrets)
}

data "aws_organizations_organization" "this" {}
# Create Security OU
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

# Create Workloads OU
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

# Create SCP to deny S3 bucket creation
resource "aws_organizations_policy" "deny_s3_creation" {
  name        = "deny-s3-bucket-creation"
  description = "Denies the ability to create S3 buckets"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyS3BucketCreation"
        Effect = "Deny"
        Action = [
          "s3:CreateBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Attach the SCP to the Workloads OU
resource "aws_organizations_policy_attachment" "attach_to_workloads" {
  policy_id = aws_organizations_policy.deny_s3_creation.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

# Example account in Security OU
resource "aws_organizations_account" "security_account" {
  name      = "security-${var.account_name}"
  email     = "security-${var.account_email}"
  role_name = var.account_role_name
  parent_id = aws_organizations_organizational_unit.security.id

  depends_on = [aws_organizations_organizational_unit.security]
}

# Example account in Workloads OU
resource "aws_organizations_account" "workload_account" {
  name      = "workload-${var.account_name}"
  email     = "workload-${var.account_email}"
  role_name = var.account_role_name
  parent_id = aws_organizations_organizational_unit.workloads.id

  depends_on = [aws_organizations_organizational_unit.workloads]
}
