variable "cpa_oidc_thumbprint" {
  type        = string
  description = "SHA-1 thumbprint of the top intermediate CA for the CPA OIDC issuer TLS certificate."
  default     = "e7b8b5a6743ce1b2f17b041de59558a41472d70c"

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.cpa_oidc_thumbprint))
    error_message = "cpa_oidc_thumbprint must use 40 lowercase hexadecimal characters."
  }
}
