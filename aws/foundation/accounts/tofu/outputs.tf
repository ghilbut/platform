output "domains_account_id" {
  description = "Domains AWS account ID."
  value       = aws_organizations_account.domains.id
}

output "platform_account_id" {
  description = "Platform AWS account ID."
  value       = aws_organizations_account.platform.id
}

output "ultary_domains_account_id" {
  description = "UltaryDomains AWS account ID."
  value       = aws_organizations_account.ultary.id
}
