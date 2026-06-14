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
