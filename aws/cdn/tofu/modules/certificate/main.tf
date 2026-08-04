locals {
  default_tags = {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/certificate/"
  }
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.acm_domain_name
  subject_alternative_names = var.fqdns
  validation_method         = "DNS"

  lifecycle { create_before_destroy = true }

  tags = merge(local.default_tags, { Name = "${var.name}-certificate" })
}

removed {
  from = aws_route53_record.validation

  lifecycle {
    destroy = false
  }
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  validation_record_fqdns = sort([
    for option in aws_acm_certificate.this.domain_validation_options : trimsuffix(option.resource_record_name, ".")
  ])
}
