output "shared_services_account_id" {
  description = "SharedServices AWS account ID."
  value       = local.shared_services_account_id
}

output "deployer_role_arn" {
  description = "CI/CD source role ARN for OpenTofu and workload deployment."
  value       = aws_iam_role.deployer.arn
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

output "backup_bucket_name" {
  description = "Platform backup bucket name."
  value       = aws_s3_bucket.backups.id
}

output "cpa_snapshot_writer_arn" {
  description = "CPA K3s snapshot writer IAM user ARN."
  value       = aws_iam_user.cpa_snapshot.arn
}

output "vault_backup_prefix" {
  description = "S3 object prefix managed by the CPA Vault backup ServiceAccount."
  value       = local.vault_backup_prefix
}

output "vault_backup_role_arn" {
  description = "SharedServices IAM role assumed by the CPA Vault backup ServiceAccount."
  value       = aws_iam_role.vault_backup.arn
}
