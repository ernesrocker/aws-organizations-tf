variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for provider operations (some Organizations APIs require an AWS partition/region; region is required by provider)."
}

variable "ou_name" {
  type        = string
  default     = "example-ou"
  description = "Name of the Organizational Unit to create."
}

variable "account_name" {
  type        = string
  default     = "example-account"
  description = "Name for the new AWS Account created under the Organization."
}

variable "account_email" {
  type        = string
  default     = "example+account@example.com"
  description = "Email address for the new account (must be unique). Replace with a real email."
}

variable "account_role_name" {
  type        = string
  default     = "OrganizationAccountAccessRole"
  description = "Role name created in the new account that the management account can assume."
}
