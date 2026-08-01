variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for the account that hosts Vault."
  default     = "ultary-domains"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for IAM Roles Anywhere and the Vault KMS key."
  default     = "us-east-1"
}

variable "vault_kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used by Vault's AWS KMS seal."

  validation {
    condition     = can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/", var.vault_kms_key_arn))
    error_message = "vault_kms_key_arn must be a KMS key ARN, not an alias ARN."
  }
}
