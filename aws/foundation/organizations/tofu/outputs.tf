output "organization_id" {
  description = "AWS Organizations organization ID."
  value       = aws_organizations_organization.this.id
}

output "root_id" {
  description = "AWS Organizations Root ID."
  value       = one(aws_organizations_organization.this.roots).id
}

output "infrastructure_ou_id" {
  description = "Infrastructure organizational unit ID."
  value       = aws_organizations_organizational_unit.infrastructure.id
}

output "member_account_protection_policy_id" {
  description = "Member account protection service control policy ID."
  value       = aws_organizations_policy.member_account_protection.id
}
