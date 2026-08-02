variable "project" {
  type    = string
  default = "platform"
}

variable "service" {
  type    = string
  default = "cdn"
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user that owns the repository"
  default     = "ghilbut"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name to receive CDN Actions variables"
  default     = "platform"
}

variable "name" {
  type        = string
  description = "Short CDN identifier used in resource names and Name tags"
  default     = "cdn"
}

variable "default_tags" {
  type    = map(string)
  default = {}

  validation {
    condition = length(merge(var.default_tags, {
      created_by             = "opentofu"
      managed_by             = "opentofu"
      project                = ""
      service                = ""
      "opentofu/module/repo" = ""
      "opentofu/module/path" = ""
      Name                   = ""
    })) <= 10
    error_message = "default_tags must leave room for the CDN module and Name tags; S3 objects support at most 10 tags."
  }
}

variable "acm_domain_name" {
  type        = string
  description = <<-EOT
    Apex domain for the ACM certificate primary domain (e.g. "ghilbut.com").
    This MUST be the organisation's apex domain — not a subdomain — so that
    a single certificate can cover all CDN hosts via SANs.
    A public Route53 hosted zone for this domain must exist in the same AWS
    account; it is looked up independently and does not need to be a key in
    var.zones.
  EOT
  default     = "ghilbut.com"
}

variable "zones" {
  type = map(map(object({
    mode          = string
    redirect_host = optional(string)
  })))
  description = <<-EOT
    CDN zone and host configuration.
    Key: root domain (e.g. "ghilbut.com")
    Value: map of relative host name -> host config
      mode: "file" | "spa" | "redirect"
      redirect_host: target FQDN, required when mode = "redirect"
  EOT
  default = {
    "ghilbut.com" = {
      "oidc.k3s" = { mode = "file" }
    }
  }

  validation {
    condition = alltrue(flatten([
      for zone, hosts in var.zones : [
        for host, cfg in hosts :
        contains(["file", "spa", "redirect"], cfg.mode)
      ]
    ]))
    error_message = "host.mode must be one of: file, spa, redirect."
  }

  validation {
    condition = alltrue(flatten([
      for zone, hosts in var.zones : [
        for host, cfg in hosts :
        cfg.mode != "redirect" || cfg.redirect_host != null
      ]
    ]))
    error_message = "redirect_host is required when mode = \"redirect\"."
  }
}
