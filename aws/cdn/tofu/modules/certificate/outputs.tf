output "arn" { value = aws_acm_certificate.this.arn }
output "validation" { value = aws_acm_certificate_validation.this.id }
output "zone_ids" { value = local.zone_id_by_root }
