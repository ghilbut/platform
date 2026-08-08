output "security_tooling_account_id" {
  description = "SecurityTooling AWS account ID."
  value       = local.security_tooling_account_id
}

output "tofu_apply_role_arn" {
  description = "SecurityTooling OpenTofu apply execution role ARN."
  value       = aws_iam_role.tofu_apply.arn
}

output "tofu_plan_role_arn" {
  description = "SecurityTooling OpenTofu plan execution role ARN."
  value       = aws_iam_role.tofu_plan.arn
}

output "cpa_oidc_provider_arn" {
  description = "SecurityTooling IAM OIDC provider ARN for CPA workloads."
  value       = aws_iam_openid_connect_provider.cpa.arn
}

output "vault_unseal_kms_key_arn" {
  description = "SecurityTooling AWS KMS key ARN for CPA Vault auto-unseal."
  value       = aws_kms_key.vault_unseal.arn
}

output "vault_unseal_role_arn" {
  description = "SecurityTooling IAM role assumed by the CPA Vault server."
  value       = aws_iam_role.vault_unseal.arn
}
