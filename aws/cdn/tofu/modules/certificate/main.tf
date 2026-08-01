data "aws_route53_zone" "zones" {
  for_each = var.zones

  name         = each.key
  private_zone = false
}

data "aws_route53_zone" "acm_domain" {
  name         = var.acm_domain_name
  private_zone = false
}

locals {
  default_tags = merge(var.default_tags, {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/certificate/"
  })

  zone_id_by_root = merge(
    { for zone, value in data.aws_route53_zone.zones : zone => value.zone_id },
    { (var.acm_domain_name) = data.aws_route53_zone.acm_domain.zone_id },
  )
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.acm_domain_name
  subject_alternative_names = var.fqdns
  validation_method         = "DNS"

  lifecycle { create_before_destroy = true }

  tags = merge(local.default_tags, { Name = "${var.name}-certificate" })
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone_id = local.zone_id_by_root[one([
        for zone in keys(local.zone_id_by_root) : zone
        if dvo.domain_name == zone || endswith(dvo.domain_name, ".${zone}")
      ])]
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
