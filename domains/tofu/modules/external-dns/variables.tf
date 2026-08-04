variable "cluster_name" {
  type        = string
  description = "Cluster identifier included in IAM resource names."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.cluster_name))
    error_message = "cluster_name must use lowercase letters, digits, and hyphens."
  }
}

variable "hosted_zone_names" {
  type        = set(string)
  description = "Public Route 53 hosted zones available to external-dns."
}

variable "name" {
  type        = string
  description = "Resource name prefix."
}

variable "oidc_issuer" {
  type        = string
  description = "Kubernetes ServiceAccount OIDC issuer URL."
}

variable "record_names" {
  type        = set(string)
  description = "DNS record names external-dns may change."
}

variable "service_account_name" {
  type        = string
  description = "external-dns ServiceAccount allowed to assume the role."
}

variable "service_account_namespace" {
  type        = string
  description = "Namespace of the external-dns ServiceAccount."
}

variable "txt_prefix" {
  type        = string
  description = "Prefix external-dns uses for TXT ownership records."
}
