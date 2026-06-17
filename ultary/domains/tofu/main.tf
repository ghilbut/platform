################################################################
##  AWS Route53 Hosted Zones
################################################################

locals {
  domains = toset([
    "dokevy.com",
    "dokevy.in",
    "dokevy.io",
    "dokevy.net",
    "polykube.com",
    "polykube.guide",
    "polykube.in",
    "polykube.io",
    "polykube.net",
    "ultary.co",
    "ultary.guide",
    "ultary.in",
    "ultary.io",
  ])

  contact = {
    address_line_1    = "분당구 성남대로 171번길 17"
    address_line_2    = "(금곡동, 씨티밸리) 811호"
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

  zone_id = aws_route53_zone.this[var.root_domain].zone_id
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
##  Root domain ultary.co
################################################################

resource "aws_route53_record" "google_mx" {
  zone_id = aws_route53_zone.this["ultary.co"].zone_id
  name    = ""
  type    = "MX"
  ttl     = 300
  records = [
    "1 ASPMX.L.GOOGLE.COM.",
    "5 ALT1.ASPMX.L.GOOGLE.COM.",
    "5 ALT2.ASPMX.L.GOOGLE.COM.",
    "10 ALT3.ASPMX.L.GOOGLE.COM.",
    "10 ALT4.ASPMX.L.GOOGLE.COM.",
  ]
}

resource "aws_route53_record" "google_dkim" {
  name    = "ultary._domainkey"
  records = [var.ultary_co_dkim_for_root_domain]
  ttl     = aws_route53_record.google_mx.ttl
  type    = "TXT"
  zone_id = aws_route53_record.google_mx.zone_id
}

resource "aws_route53_record" "google_apps" {
  # Customize a Google Workspace service URL
  #  * https://support.google.com/a/answer/53340?fl=1

  for_each = toset([
    "calendar",
    "docs",
    "drive",
    "mail",
    "groups",
    "sites",
  ])

  zone_id = local.zone_id
  name    = each.key
  type    = "CNAME"
  ttl     = 300
  records = ["ghs.googlehosted.com"]
}

################################################################
##  Subdomains
################################################################

##--------------------------------------------------------------
##  ultary.co

resource "aws_route53_record" "ultary_co_txt_records" {
  for_each = var.ultary_co_txt_for_sub_domains

  name    = each.key
  records = [each.value]
  ttl     = 300
  type    = "TXT"
  zone_id = local.zone_id
}

resource "aws_route53_record" "ultary_co_cname_records" {
  for_each = toset(keys(aws_route53_record.ultary_co_txt_records))

  name    = var.ultary_co_cname_for_sub_domains[each.key].name
  records = [var.ultary_co_cname_for_sub_domains[each.key].record]
  ttl     = 300
  type    = "CNAME"
  zone_id = local.zone_id
}

resource "aws_route53_record" "ultary_co_mx_records" {
  for_each = toset(keys(aws_route53_record.ultary_co_txt_records))

  name    = each.key
  records = ["1 SMTP.GOOGLE.COM"]
  ttl     = 300
  type    = "MX"
  zone_id = local.zone_id
}

resource "aws_route53_record" "ultary_co_dkim_records" {
  for_each = toset(keys(aws_route53_record.ultary_co_txt_records))

  name    = "google._domainkey.${each.key}"
  records = [var.ultary_co_dkim_for_sub_domains[each.key]]
  ttl     = 300
  type    = "TXT"
  zone_id = local.zone_id
}
