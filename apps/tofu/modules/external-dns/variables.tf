variable "cluster_name" {
  type        = string
  description = "Cluster identifier included in external-dns IAM resource names."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.cluster_name))
    error_message = "cluster_name must use lowercase letters, digits, and hyphens."
  }
}

variable "hosted_zone_names" {
  type        = set(string)
  description = "Public Route 53 hosted zones external-dns may read."
}

variable "name" {
  type        = string
  description = "Platform name prefix for external-dns IAM resources."
}

variable "oidc_issuer" {
  type        = string
  description = "Public Kubernetes ServiceAccount OIDC issuer URL for this cluster."
}

variable "record_names" {
  type        = set(string)
  description = "DNS record names external-dns may change."
}

variable "service_account_name" {
  type        = string
  description = "Name of the external-dns ServiceAccount allowed to assume the role."
}

variable "service_account_namespace" {
  type        = string
  description = "Namespace of the external-dns ServiceAccount allowed to assume the role."
}

variable "txt_prefix" {
  type        = string
  description = "Prefix external-dns uses for TXT ownership records."
}
