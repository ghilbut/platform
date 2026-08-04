output "tofu_execution_role_arn" {
  description = "Domains OpenTofu execution role ARN."
  value       = module.tofu_execution_role.arn
}
