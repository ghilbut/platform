output "profile_arn" {
  description = "IAM Roles Anywhere profile ARN."
  value       = aws_rolesanywhere_profile.vault.arn
}

output "role_arn" {
  description = "IAM role ARN assumed through IAM Roles Anywhere."
  value       = aws_iam_role.vault.arn
}

output "trust_anchor_arn" {
  description = "IAM Roles Anywhere trust anchor ARN."
  value       = aws_rolesanywhere_trust_anchor.vault.arn
}
