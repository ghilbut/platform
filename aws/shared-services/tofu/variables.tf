variable "aws_execution_role_arn" {
  type        = string
  description = "Account-local OpenTofu execution role assumed by the AWS provider. Set null only while bootstrapping the execution roles."
  default     = "arn:aws:iam::012646747332:role/tofu-plan"
  nullable    = true

  validation {
    condition = var.aws_execution_role_arn == null || contains([
      "arn:aws:iam::012646747332:role/tofu-plan",
      "arn:aws:iam::012646747332:role/tofu-apply",
    ], var.aws_execution_role_arn)
    error_message = "aws_execution_role_arn must be null or the SharedServices account tofu-plan or tofu-apply role ARN."
  }
}

variable "cpa_oidc_thumbprint" {
  type        = string
  description = "SHA-1 thumbprint of the top intermediate CA for the CPA OIDC issuer TLS certificate."
  default     = "e7b8b5a6743ce1b2f17b041de59558a41472d70c"

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.cpa_oidc_thumbprint))
    error_message = "cpa_oidc_thumbprint must use 40 lowercase hexadecimal characters."
  }
}
