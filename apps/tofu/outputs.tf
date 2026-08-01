output "awsra_profile_arn" {
  description = "IAM Roles Anywhere profile ARN for Vault's credential-process configuration."
  value       = module.awsra.profile_arn
}

output "awsra_role_arn" {
  description = "IAM role ARN assumed by Vault through IAM Roles Anywhere."
  value       = module.awsra.role_arn
}

output "awsra_trust_anchor_arn" {
  description = "IAM Roles Anywhere trust anchor ARN for Vault's credential-process configuration."
  value       = module.awsra.trust_anchor_arn
}

output "vault_kms_key_arn" {
  description = "KMS key ARN for Vault's AWS KMS seal configuration."
  value       = aws_kms_key.vault.arn
}
