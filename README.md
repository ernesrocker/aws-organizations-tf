# aws-organizations-tf

Terraform configuration for managing AWS Organizations accounts, policies, and shared infrastructure.

## Optional: Local Deployment

1. Install Terraform v1.5+ and the AWS CLI; ensure your IAM user or role can manage AWS Organizations.
2. Authenticate with `aws configure` or export `AWS_PROFILE` and `AWS_REGION`.
3. Move into `environments/<account>/<stage>` and review the provided `backend.hcl` and `*.tfvars`.
4. Run `terraform init -backend-config=backend.hcl` to configure providers and state.
5. Run `terraform plan -var-file=<stage>.tfvars` to verify the change set.
6. Apply with `terraform apply -var-file=<stage>.tfvars` only when you are ready to deploy those changes.

This repository contains a small, opinionated example showing how to provision an AWS Organization, Organizational Units (OUs), example member accounts, and a Service Control Policy (SCP) that prevents S3 bucket creation in a Workloads OU. It also includes a GitHub Actions workflow that demonstrates OIDC-based credentialing and how to pass Terraform input variables from repository secrets.

IMPORTANT: This is an example. Creating an Organization and AWS accounts is a real, global change with billing and operational impact. Run in a sandbox account and review all plans before applying.

## What's in this repo

- `terraform/` — Terraform configuration that creates an Organization (or uses an existing one), two OUs (`Security` and `Workloads`), example member accounts, an SCP that denies S3 bucket creation, and attachments.
- `.github/workflows/deploy.yml` — GitHub Actions workflow that uses OIDC to assume an AWS role and runs `terraform init/validate/plan` and `apply` (apply is executed only for pushes to `master`).

## Quick local deploy (safe steps)

Prerequisites

- Terraform 1.3+ installed
- AWS CLI installed and configured with credentials for the management account (the account that will own the Organization)
- An email address you control for each member AWS account you plan to create (must be unique)

Example local workflow (zsh)

1. Create or edit `terraform/terraform.tfvars` with real values (example below).

```hcl
# terraform/terraform.tfvars
account_name      = "security-prod"
account_email     = "me+security@example.com"    # MUST be a real, unique email you control
account_role_name = "OrganizationAccountAccessRole"
aws_region        = "us-east-1"
```

2. Run Terraform commands from the `terraform/` directory:

```bash
cd terraform
terraform init
terraform validate
terraform plan -out=tfplan -input=false
# inspect the plan carefully
terraform show tfplan
# when you're certain, apply (this creates real AWS accounts)
terraform apply -input=false -auto-approve tfplan
```

Safety tips

- Always review `terraform plan` before `apply`. Plans are snapshots — don’t apply a stale plan created earlier without re-checking.
- Back up your `terraform.tfstate` before making big changes: `cp terraform.tfstate terraform.tfstate.bak`
- If an Organization already exists and you don't want Terraform to delete it, import it into state or convert the resource to a data source (see next section).

## Organization management: import vs manage vs reference

- If you want Terraform to create and manage the Organization, run the configuration with credentials for the management account. The `aws_organizations_organization` resource will create the org.
- If the Organization already exists and you want Terraform to reference it (but not manage its lifecycle), replace the resource with a data source:

```hcl
data "aws_organizations_organization" "existing" {}
# then use data.aws_organizations_organization.existing.roots[0].id as parent_id
```

- If the Organization exists but is missing from Terraform state, you can import it:

```bash
# get org id from CLI: aws organizations describe-organization
terraform import aws_organizations_organization.org o-xxxxxxxx
```

If Terraform attempts to destroy the Organization unexpectedly, stop and inspect the plan. Deleting an Organization is destructive and requires removing all member accounts first; it is rarely what you want.

## Service Control Policies (SCPs) and policy types

- SCPs require the `SERVICE_CONTROL_POLICY` policy type to be enabled on the root. The repo includes a helper `null_resource` that attempts to enable this via the AWS CLI and polls until the type is `ENABLED`. That means:
  - Locally: the machine running Terraform must have the AWS CLI installed and configured with the management account credentials.
  - In CI: the runner must have the AWS CLI installed (or you can enable the policy type manually from the console/CLI beforehand).

Manual enable example (one-time):

```bash
root_id=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
aws organizations enable-policy-type --root-id "$root_id" --policy-type SERVICE_CONTROL_POLICY
aws organizations list-roots --query "Roots[?Id=='$root_id'].PolicyTypes" --output json
```

## GitHub Actions / CI notes

- The workflow uses GitHub OIDC to assume a role in your AWS account — avoid storing long-lived AWS keys in GitHub.
- Required repository secrets (recommended names):

  - `AWS_ROLE_TO_ASSUME` — ARN of the role GitHub will assume (via OIDC).
  - `ACCOUNT_NAME` — passed into Terraform as `TF_VAR_account_name`.
  - `ACCOUNT_EMAIL` — passed into Terraform as `TF_VAR_account_email` (must be a real email).
  - `ACCOUNT_ROLE_NAME` — optional override for the role created in new accounts.

- If you keep the `null_resource` that enables service control policies, the CI runner must have the AWS CLI installed (I can add a step to the workflow to install it if you want).

## Outputs

After a successful apply the Terraform outputs include IDs you can use in downstream automation:

- `organization_id` — the organization id (o-...)
- `security_ou_id` — the Security OU id
- `workloads_ou_id` — the Workloads OU id
- `deny_s3_policy_id` — the policy id for the deny S3 SCP
- `security_account_id` / `workload_account_id` — the member account ids created

## Troubleshooting checklist

- Confirm which AWS credentials Terraform is using:
  ```bash
  aws sts get-caller-identity
  ```
- Check whether the calling account is a management account and whether an Organization exists:
  ```bash
  aws organizations describe-organization
  aws organizations list-roots --output json
  aws organizations list-accounts --output table
  ```
- If an SCP attachment fails with `PolicyTypeNotEnabledException`, enable `SERVICE_CONTROL_POLICY` on the root (manual or via the provided helper) and re-run apply.
- If Terraform plans to destroy the Organization unexpectedly, back up state and either import the org or remove the managed resource from state with `terraform state rm aws_organizations_organization.org` and switch to the `data` source.

## Next steps I can help with

- Add a `terraform.tfvars.example` and a remote S3 backend example.
- Add a CI step to install the AWS CLI (so the `null_resource` can run in GitHub Actions).
- Convert the repo to reference an existing organization via a `data` source instead of managing the org lifecycle.

If you'd like any of those, tell me which one and I'll implement it.
