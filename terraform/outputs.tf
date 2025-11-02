output "organization_id" {
  value       = data.aws_organizations_organization.this.roots[0].id
  description = "The Organizations organization id"
}

output "security_ou_id" {
  value       = aws_organizations_organizational_unit.security.id
  description = "ID of the Security OU"
}

output "workloads_ou_id" {
  value       = aws_organizations_organizational_unit.workloads.id
  description = "ID of the Workloads OU"
}

output "deny_s3_policy_id" {
  value       = aws_organizations_policy.deny_s3_creation.id
  description = "ID of the SCP that denies S3 bucket creation"
}

output "security_account_id" {
  value       = aws_organizations_account.security_account.id
  description = "The created Security account id"
}

output "workload_account_id" {
  value       = aws_organizations_account.workload_account.id
  description = "The created Workload account id"
}
