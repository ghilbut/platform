variable "name" {
  type        = string
  description = "Name prefix for Vault resources."
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the IAM OIDC provider that verifies CPA ServiceAccount tokens."
}

variable "oidc_issuer" {
  type        = string
  description = "Public CPA Kubernetes ServiceAccount OIDC issuer URL."
}

variable "service_account_name" {
  type        = string
  description = "Name of the Vault ServiceAccount allowed to assume the role."
}

variable "service_account_namespace" {
  type        = string
  description = "Namespace of the Vault ServiceAccount allowed to assume the role."
}
