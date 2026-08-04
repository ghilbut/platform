output "state_bucket_arn" {
  description = "OpenTofu state bucket ARN."
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_name" {
  description = "OpenTofu state bucket name."
  value       = aws_s3_bucket.state.id
}
