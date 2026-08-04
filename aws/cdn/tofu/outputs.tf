output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution Route 53 hosted zone ID."
  value       = module.cloudfront.hosted_zone_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.id
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.arn
}

output "lambda_function_arn" {
  description = "Lambda@Edge function ARN (versioned)"
  value       = module.edge.lambda_function_arn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.certificate.arn
}

output "certificate_validation_options" {
  description = "DNS validation records required by the ACM certificate."
  value       = module.certificate.validation_options
}

output "platform_certificate_arn" {
  description = "Platform ACM certificate ARN."
  value       = module.certificate_platform.arn
}

output "platform_certificate_validation_options" {
  description = "DNS validation records required by the Platform ACM certificate."
  value       = module.certificate_platform.validation_options
}

output "fqdns" {
  description = "CDN host names published through Route 53."
  value       = local.fqdns
}

output "github_actions_role_arn" {
  description = "IAM role ARN for CDN GitHub Actions uploads"
  value       = module.github_actions.role_arn
}
