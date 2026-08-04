################################################################
##  AWS Route53 Hosted Zones
################################################################

locals {
  domains = toset([
    "ghilbut.com",
    "ghilbut.net",
  ])

  root_domain = "ghilbut.com"

  contact = {
    address_line_1    = "분당구 성남대로 171번길17 (금곡동, 씨티밸리) 811호"
    address_line_2    = ""
    city              = "성남시"
    contact_type      = "PERSON"
    country_code      = "KR"
    email             = "ghilbut@gmail.com"
    extra_params      = {}
    fax               = ""
    first_name        = "준형"
    last_name         = "김"
    organization_name = ""
    phone_number      = "+82.1026482676"
    state             = ""
    zip_code          = "13615"
  }

  ttl     = 3600
  zone_id = aws_route53_zone.this[local.root_domain].zone_id
}

data "terraform_remote_state" "cdn" {
  backend = "s3"

  config = {
    bucket  = "ghilbut-tfstates-v2"
    encrypt = true
    key     = "platform/aws/cdn.tfstate"
    profile = "ghilbut-tofu-apply-for-domains"
    region  = "us-east-1"
  }
}

module "tofu_execution_role" {
  source = "../../aws/modules/tofu-execution-role"

  name                       = "tofu-apply-domains"
  description                = "OpenTofu execution role for Domains account Route 53 resources."
  source_account_id          = "869061964712"
  source_permission_set_name = "TofuApplyForDomains"
  sso_region                 = "us-east-1"
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Route53Management"
        Effect   = "Allow"
        Action   = ["route53:*", "route53domains:*"]
        Resource = "*"
      },
      {
        Sid    = "ReadExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
        ]
        Resource = "arn:aws:iam::869061964712:role/tofu-apply-domains"
      },
    ]
  })
}

resource "aws_route53domains_registered_domain" "this" {
  for_each = local.domains

  lifecycle {
    prevent_destroy = true
  }

  domain_name = each.key

  admin_privacy      = !endswith(each.key, ".in")
  billing_privacy    = !endswith(each.key, ".in")
  registrant_privacy = !endswith(each.key, ".in")
  tech_privacy       = !endswith(each.key, ".in")

  registrant_contact {
    address_line_1    = local.contact.address_line_1
    address_line_2    = local.contact.address_line_2
    city              = local.contact.city
    contact_type      = local.contact.contact_type
    country_code      = local.contact.country_code
    email             = local.contact.email
    extra_params      = local.contact.extra_params
    fax               = local.contact.fax
    first_name        = local.contact.first_name
    last_name         = local.contact.last_name
    organization_name = local.contact.organization_name
    phone_number      = local.contact.phone_number
    state             = local.contact.state
    zip_code          = local.contact.zip_code
  }
  admin_contact {
    address_line_1    = local.contact.address_line_1
    address_line_2    = local.contact.address_line_2
    city              = local.contact.city
    contact_type      = local.contact.contact_type
    country_code      = local.contact.country_code
    email             = local.contact.email
    extra_params      = local.contact.extra_params
    fax               = local.contact.fax
    first_name        = local.contact.first_name
    last_name         = local.contact.last_name
    organization_name = local.contact.organization_name
    phone_number      = local.contact.phone_number
    state             = local.contact.state
    zip_code          = local.contact.zip_code
  }
  tech_contact {
    address_line_1    = local.contact.address_line_1
    address_line_2    = local.contact.address_line_2
    city              = local.contact.city
    contact_type      = local.contact.contact_type
    country_code      = local.contact.country_code
    email             = local.contact.email
    extra_params      = local.contact.extra_params
    fax               = local.contact.fax
    first_name        = local.contact.first_name
    last_name         = local.contact.last_name
    organization_name = local.contact.organization_name
    phone_number      = local.contact.phone_number
    state             = local.contact.state
    zip_code          = local.contact.zip_code
  }

  dynamic "name_server" {
    for_each = toset(aws_route53_zone.this[each.key].name_servers)
    content {
      name = name_server.key
    }
  }

  tags = {
    Name = each.key
  }
}

resource "aws_route53_zone" "this" {
  for_each = local.domains

  lifecycle {
    prevent_destroy = true
  }

  name = each.key

  tags = {
    Name = each.key
  }
}

################################################################
##  Root domain ghilbut.com
################################################################

resource "aws_route53_record" "google_mx" {
  name = local.root_domain
  records = [
    "1 ASPMX.L.GOOGLE.COM.",
    "5 ALT1.ASPMX.L.GOOGLE.COM.",
    "5 ALT2.ASPMX.L.GOOGLE.COM.",
    "10 ALT3.ASPMX.L.GOOGLE.COM.",
    "10 ALT4.ASPMX.L.GOOGLE.COM.",
  ]
  ttl     = local.ttl
  type    = "MX"
  zone_id = local.zone_id
}

resource "aws_route53_record" "google_dkim" {
  name    = "google._domainkey.${local.root_domain}"
  records = [var.ghilbut_dkim_for_root_domain]
  ttl     = local.ttl
  type    = "TXT"
  zone_id = local.zone_id
}

resource "aws_route53_record" "google_apps" {
  # Customize a Google Workspace service URL
  #  * https://support.google.com/a/answer/53340?fl=1

  for_each = toset([
    "calendar",
    "drive",
    "groups",
    "mail",
  ])

  name    = "${each.key}.${local.root_domain}"
  records = ["ghs.googlehosted.com"]
  ttl     = local.ttl
  type    = "CNAME"
  zone_id = local.zone_id
}

################################################################
##  CDN records
################################################################

resource "aws_route53_record" "cdn_certificate_validation" {
  for_each = data.terraform_remote_state.cdn.outputs.certificate_validation_options

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = aws_route53_zone.this[one([
    for domain in local.domains : domain
    if each.key == domain || endswith(each.key, ".${domain}")
  ])].zone_id
}

resource "aws_route53_record" "cdn_alias" {
  for_each = toset(data.terraform_remote_state.cdn.outputs.fqdns)

  name = each.key
  type = "A"
  zone_id = aws_route53_zone.this[one([
    for domain in local.domains : domain
    if each.key == domain || endswith(each.key, ".${domain}")
  ])].zone_id

  alias {
    evaluate_target_health = false
    name                   = data.terraform_remote_state.cdn.outputs.cloudfront_domain_name
    zone_id                = data.terraform_remote_state.cdn.outputs.cloudfront_hosted_zone_id
  }
}

import {
  to = aws_route53_record.cdn_certificate_validation["ghilbut.com"]
  id = "Z193YX3H31OEZV__1f3bc0e46ca05d312b303b35e6c8d69b.ghilbut.com._CNAME"
}

import {
  to = aws_route53_record.cdn_certificate_validation["oidc.k3s.ghilbut.com"]
  id = "Z193YX3H31OEZV__249f0cc45cee4112146a0bb348aa145a.oidc.k3s.ghilbut.com._CNAME"
}

import {
  to = aws_route53_record.cdn_alias["oidc.k3s.ghilbut.com"]
  id = "Z193YX3H31OEZV_oidc.k3s.ghilbut.com_A"
}
