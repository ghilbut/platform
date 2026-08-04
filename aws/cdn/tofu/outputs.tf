output "certificate_arn" {
  description = "Platform ACM certificate ARN."
  value       = module.certificate.arn
}

output "certificate_validation_options" {
  description = "DNS validation records required by the Platform ACM certificate."
  value       = module.certificate.validation_options
}

output "cloudfront_distribution_id" {
  description = "Platform CloudFront distribution ID."
  value       = module.cloudfront.id
}

output "cloudfront_domain_name" {
  description = "Platform CloudFront distribution domain name."
  value       = module.cloudfront.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Platform CloudFront hosted zone ID."
  value       = module.cloudfront.hosted_zone_id
}

output "github_actions_role_arn" {
  description = "Platform IAM role ARN for CDN GitHub Actions uploads."
  value       = module.github_actions.role_arn
}

output "s3_bucket_name" {
  description = "Platform CDN origin bucket name."
  value       = module.s3.name
}

output "fqdns" {
  description = "CDN host names published through Route 53."
  value       = local.fqdns
}
