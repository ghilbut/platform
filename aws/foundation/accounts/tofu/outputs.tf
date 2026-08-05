output "domains_account_id" {
  description = "Domains AWS account ID."
  value       = aws_organizations_account.domains.id
}

output "shared_services_account_id" {
  description = "SharedServices AWS account ID."
  value       = aws_organizations_account.shared_services.id
}

output "ultary_domains_account_id" {
  description = "UltaryDomains AWS account ID."
  value       = aws_organizations_account.ultary.id
}
