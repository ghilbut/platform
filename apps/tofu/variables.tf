variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for the account that owns platform application resources."
  default     = "ghilbut-platform"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for platform application resources."
  default     = "us-east-1"
}

variable "cpa_oidc_issuer" {
  type        = string
  description = "Public CPA Kubernetes ServiceAccount OIDC issuer registered in IAM."
  default     = "https://oidc.k3s.ghilbut.com/cpa"

  validation {
    condition     = can(regex("^https://[^/]+/.+", var.cpa_oidc_issuer))
    error_message = "cpa_oidc_issuer must be an HTTPS URL with a path."
  }
}

variable "cpa_oidc_thumbprint" {
  type        = string
  description = "SHA-1 thumbprint of the top intermediate CA for the CPA OIDC issuer TLS certificate."
  default     = "e7b8b5a6743ce1b2f17b041de59558a41472d70c"

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.cpa_oidc_thumbprint))
    error_message = "cpa_oidc_thumbprint must be a lowercase 40-character SHA-1 value."
  }
}
