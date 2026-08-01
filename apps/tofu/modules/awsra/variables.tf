variable "name" {
  type        = string
  description = "Name prefix for the IAM role, profile, and trust anchor."
}

variable "trust_anchor_certificate_path" {
  type        = string
  description = "Path to the PEM-encoded issuing CA certificate trusted by IAM Roles Anywhere."
}

variable "certificate_subject_common_name" {
  type        = string
  description = "Common Name of the leaf certificate permitted to assume the role."
}

variable "manifest_directory_path" {
  type        = string
  description = "Directory where the generated AWS Roles Anywhere ConfigMap manifest is written."
}

variable "pkcs8_password_file_path" {
  type        = string
  description = "Path to the PKCS#8 private-key passphrase file."
}

variable "pkcs8_password_revision" {
  type        = number
  description = "Revision number incremented when the PKCS#8 passphrase changes."
}

variable "session_duration_seconds" {
  type        = number
  description = "Lifetime of credentials issued by the IAM Roles Anywhere profile."
  default     = 3600

  validation {
    condition     = var.session_duration_seconds >= 900 && var.session_duration_seconds <= 43200
    error_message = "session_duration_seconds must be between 900 and 43200 seconds."
  }
}
