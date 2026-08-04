variable "name" {
  type        = string
  description = "Resource name prefix."
}

variable "cluster_name" {
  type        = string
  description = "Cluster identifier included in IAM resource names."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.cluster_name))
    error_message = "cluster_name must use lowercase letters, digits, and hyphens."
  }
}

variable "oidc_issuer" {
  type        = string
  description = "Kubernetes ServiceAccount OIDC issuer URL."
}

variable "service_account_name" {
  type        = string
  description = "cert-manager ServiceAccount allowed to assume the role."
}

variable "service_account_namespace" {
  type        = string
  description = "Namespace of the cert-manager ServiceAccount."
}

variable "hosted_zone_names" {
  type        = set(string)
  description = "Public Route 53 hosted zones available for DNS-01 challenges."
}
