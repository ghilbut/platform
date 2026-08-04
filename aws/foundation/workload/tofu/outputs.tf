output "platform_account_id" {
  description = "Platform AWS account ID."
  value       = local.platform_account_id
}

output "tofu_execution_role_arn" {
  description = "Platform workload OpenTofu execution role ARN."
  value       = module.tofu_execution_role.arn
}

output "cpa_oidc_provider_arn" {
  description = "Platform IAM OIDC provider ARN for CPA workloads."
  value       = aws_iam_openid_connect_provider.cpa.arn
}
