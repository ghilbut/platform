output "tofu_execution_role_arn" {
  description = "Domains OpenTofu execution role ARN."
  value       = module.tofu_execution_role.arn
}

output "cpa_cert_manager_role_arn" {
  description = "Domains role assumed by CPA cert-manager."
  value       = module.cpa_cert_manager.role_arn
}

output "cpa_external_dns_role_arn" {
  description = "Domains role assumed by CPA external-dns."
  value       = module.cpa_external_dns.role_arn
}
