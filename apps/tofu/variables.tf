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
  description = "Public CPA Kubernetes ServiceAccount OIDC issuer registered by k3s/tofu in IAM."
  default     = "https://oidc.k3s.ghilbut.com/cpa"

  validation {
    condition     = can(regex("^https://[^/]+/.+", var.cpa_oidc_issuer))
    error_message = "cpa_oidc_issuer must be an HTTPS URL with a path."
  }
}
