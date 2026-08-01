variable "cloudfront_domain_name" { type = string }
variable "cloudfront_hosted_zone_id" { type = string }
variable "fqdns" { type = list(string) }
variable "zone_ids" { type = map(string) }
variable "zones" { type = map(map(any)) }
