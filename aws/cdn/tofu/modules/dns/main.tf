variable "cloudfront_domain_name" { type = string }
variable "cloudfront_hosted_zone_id" { type = string }
variable "fqdns" { type = list(string) }
variable "zone_ids" { type = map(string) }
variable "zones" { type = map(map(any)) }

resource "aws_route53_record" "this" {
  for_each = {
    for fqdn in var.fqdns : fqdn => var.zone_ids[one([
      for zone in keys(var.zones) : zone
      if fqdn == zone || endswith(fqdn, ".${zone}")
    ])]
  }

  name    = each.key
  type    = "A"
  zone_id = each.value
  alias {
    evaluate_target_health = false
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
  }
}
