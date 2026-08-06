variable "project" {
  type    = string
  default = "platform"
}

variable "service" {
  type    = string
  default = "cdn"
}

variable "aws_execution_role_arn" {
  type        = string
  description = "Account-local OpenTofu execution role assumed by the AWS provider."
  default     = "arn:aws:iam::012646747332:role/tofu-plan"
  nullable    = true

  validation {
    condition = var.aws_execution_role_arn == null || contains([
      "arn:aws:iam::012646747332:role/tofu-plan",
      "arn:aws:iam::012646747332:role/tofu-apply",
    ], var.aws_execution_role_arn)
    error_message = "aws_execution_role_arn must be null or the SharedServices account tofu-plan or tofu-apply role ARN."
  }
}

variable "name" {
  type        = string
  description = "Short CDN identifier used in resource names and Name tags"
  default     = "cdn-platform"
}

variable "acm_domain_name" {
  type        = string
  description = <<-EOT
    Apex domain for the ACM certificate primary domain (e.g. "ghilbut.com").
    This MUST be the organisation's apex domain — not a subdomain — so that
    a single certificate can cover all CDN hosts via SANs.
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
