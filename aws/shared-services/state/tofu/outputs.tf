output "tofu_state_admin_role_arn" {
  description = "OpenTofu state bucket administration role ARN."
  value       = aws_iam_role.tofu_state_admin.arn
}

output "state_bucket_arn" {
  description = "OpenTofu state bucket ARN."
  value       = aws_s3_bucket.state["primary"].arn
}

output "state_bucket_name" {
  description = "OpenTofu state bucket name."
  value       = aws_s3_bucket.state["primary"].id
}
