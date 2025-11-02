# Repository Guidelines

## Project Structure & Module Organization
- Place reusable Terraform modules under `modules/<service>` with concise READMEs describing inputs, outputs, and usage.
- Keep environment definitions in `environments/<account>/<stage>` with `backend.hcl`, `main.tf`, and the matching `*.tfvars` files.
- Store shared policies and data sources in `shared/` so multiple stacks can consume a single definition.

## Build, Test, and Development Commands
- `terraform fmt` – normalizes formatting across all `.tf` files before review.
- `terraform init -backend-config=environments/dev/backend.hcl` – sets up providers and state for the chosen environment.
- `terraform validate` – checks syntax and provider constraints after each module or variable change.
- `terraform plan -var-file=environments/dev/dev.tfvars` – previews pending changes; share the output in pull requests.

## Coding Style & Naming Conventions
- Use two-space indentation with aligned `=` for Terraform blocks; keep blocks alphabetized where practical for readability.
- Prefer lower_snake_case for variables and outputs, and dash-separated names for AWS resources (e.g., `org-master-account`).
- Keep module inputs explicit; avoid inheriting provider configuration from parent stacks.
- Run `terraform fmt` and `terraform validate` before pushing to ensure consistent formatting and basic checks.

## Testing Guidelines
- Treat `terraform validate` and `terraform plan` as the minimum test suite; both must succeed before review.
- For complex modules, add Terratest coverage under `tests/` with Go subpackages that mirror module names.
- Snapshot plan JSON (`terraform show -json plan.out`) when possible to guard against unexpected resource churn.

## Commit & Pull Request Guidelines
- Follow the lightweight convention `area: short summary` (e.g., `ou: add finance unit policies`); keep subject lines under 72 characters.
- Bundle changes per environment or module to simplify rollbacks and reviews.
- Each PR should include a brief summary, links to related issues or RFCs, the relevant plan output snippet, and notes on manual steps required post-merge.
- Request reviews from at least one maintainer of the touched module or environment; re-run plans if the branch diverges from main.

## Security & Configuration Tips
- Never check in credentials or raw state files; rely on remote backends and reference secrets via AWS SSM or Secrets Manager.
- Lock Terraform versions in `required_version` blocks and pin providers to vetted ranges to avoid accidental upgrades.
- Treat service control policies and IAM documents as code—store them in `shared/policies/` and test changes in a sandbox account before promoting.
