variable "name" {
  type        = string
  description = "Name prefix for Vault resources."
}

variable "awsra_role_name" {
  type        = string
  description = "IAM Roles Anywhere role name allowed to use the Vault KMS seal key."
}

variable "manifest_file_path" {
  type        = string
  description = "Path where the generated Vault ConfigMap manifest is written."
}
