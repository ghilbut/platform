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
