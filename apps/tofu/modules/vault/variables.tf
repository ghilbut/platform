variable "name" {
  type        = string
  description = "Name prefix for Vault resources."
}

variable "awsra_role_name" {
  type        = string
  description = "IAM Roles Anywhere role name allowed to use the Vault KMS seal key."
}

variable "manifest_directory_path" {
  type        = string
  description = "Directory where the generated Vault ConfigMap manifest is written."
}
