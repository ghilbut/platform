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

variable "cpa_oidc_issuer" {
  type        = string
  description = "Public CPA Kubernetes ServiceAccount OIDC issuer registered by k3s/tofu in IAM."
  default     = "https://oidc.k3s.ghilbut.com/cpa"

  validation {
    condition     = can(regex("^https://[^/]+/.+", var.cpa_oidc_issuer))
    error_message = "cpa_oidc_issuer must be an HTTPS URL with a path."
  }
}

variable "cert_manager_clusters" {
  type = map(object({
    hosted_zone_names         = set(string)
    oidc_issuer               = string
    service_account_name      = string
    service_account_namespace = string
  }))
  description = "Additional clusters that use the cert-manager module. The cpa entry is defined by this root."
  default     = {}

  validation {
    condition = alltrue([
      for cluster in values(var.cert_manager_clusters) :
      can(regex("^https://[^/]+/.+", cluster.oidc_issuer))
    ])
    error_message = "Each cert_manager_clusters OIDC issuer must be an HTTPS URL with a path."
  }
}

variable "external_dns_clusters" {
  type = map(object({
    hosted_zone_names         = set(string)
    oidc_issuer               = string
    record_names              = set(string)
    service_account_name      = string
    service_account_namespace = string
    txt_prefix                = string
  }))
  description = "Additional clusters that use the external-dns module. The cpa entry is defined by this root."
  default     = {}

  validation {
    condition = alltrue([
      for cluster in values(var.external_dns_clusters) :
      can(regex("^https://[^/]+/.+", cluster.oidc_issuer))
    ])
    error_message = "Each external_dns_clusters OIDC issuer must be an HTTPS URL with a path."
  }
}
