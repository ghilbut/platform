output "arn" { value = aws_acm_certificate.this.arn }
output "validation" { value = aws_acm_certificate_validation.this.id }

output "validation_options" {
  value = {
    for option in aws_acm_certificate.this.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }
}
