variable "name" {
  type        = string
  description = "Platform name prefix for cert-manager IAM resources."
}

variable "clusters" {
  type = map(object({
    hosted_zone_names         = set(string)
    oidc_issuer               = string
    service_account_name      = string
    service_account_namespace = string
  }))
  description = "Clusters whose cert-manager DNS01 ServiceAccount may assume the shared role and their Route 53 hosted zones."

  validation {
    condition     = length(var.clusters) > 0
    error_message = "clusters must contain at least one cluster."
  }
}
