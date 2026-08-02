variable "clusters" {
  type = map(object({
    hosted_zone_names         = set(string)
    oidc_issuer               = string
    record_names              = set(string)
    service_account_name      = string
    service_account_namespace = string
    txt_prefix                = string
  }))
  description = "Clusters whose external-dns ServiceAccount may assume the shared role and their allowed Route 53 records."

  validation {
    condition     = length(var.clusters) > 0
    error_message = "clusters must contain at least one cluster."
  }
}

variable "name" {
  type        = string
  description = "Platform name prefix for external-dns IAM resources."
}
