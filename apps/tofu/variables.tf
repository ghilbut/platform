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

variable "name" {
  type        = string
  description = "Name prefix for platform application resources."
  default     = "platform"
}

variable "kube_config_path" {
  type        = string
  description = "Path to the kubeconfig file that contains the CPA context."
  default     = "~/.kube/config"
}

variable "kube_context" {
  type        = string
  description = "Kubeconfig context for the CPA cluster."
  default     = "cpa"
}

variable "vault_manifest_directory_path" {
  type        = string
  description = "Directory where the Vault Argo CD ConfigMap manifests are written."
  default     = null
  nullable    = true
}

variable "awsra_pkcs8_password_revision" {
  type        = number
  description = "Revision number incremented when the AWS Roles Anywhere PKCS#8 passphrase changes."
  default     = 1
}
