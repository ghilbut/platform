output "shared_services_account_id" {
  description = "SharedServices AWS account ID."
  value       = local.shared_services_account_id
}

output "tofu_execution_role_arn" {
  description = "SharedServices workload OpenTofu execution role ARN."
  value       = aws_iam_role.tofu_apply.arn
}

output "tofu_state_apply_role_arn" {
  description = "OpenTofu Apply backend state role ARN."
  value       = aws_iam_role.tofu_state_apply.arn
}

output "tofu_state_readonly_role_arn" {
  description = "OpenTofu read-only backend state role ARN."
  value       = aws_iam_role.tofu_state_readonly.arn
}

output "cpa_oidc_provider_arn" {
  description = "SharedServices IAM OIDC provider ARN for CPA workloads."
  value       = aws_iam_openid_connect_provider.cpa.arn
}

output "state_bucket_arn" {
  description = "OpenTofu state bucket ARN."
  value       = aws_s3_bucket.state["primary"].arn
}

output "state_bucket_name" {
  description = "OpenTofu state bucket name."
  value       = aws_s3_bucket.state["primary"].id
}
