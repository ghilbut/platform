output "arn" { value = aws_cloudfront_distribution.this.arn }
output "domain_name" { value = aws_cloudfront_distribution.this.domain_name }
output "hosted_zone_id" { value = aws_cloudfront_distribution.this.hosted_zone_id }
output "origin_access_control_arn" { value = aws_cloudfront_origin_access_control.this.arn }
output "id" { value = aws_cloudfront_distribution.this.id }
