output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
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

output "github_actions_role_arn" {
  description = "IAM role ARN for CDN GitHub Actions uploads"
  value       = module.github_actions.role_arn
}
