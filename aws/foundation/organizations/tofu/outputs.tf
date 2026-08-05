output "organization_id" {
  description = "AWS Organizations organization ID."
  value       = aws_organizations_organization.this.id
}

output "root_id" {
  description = "AWS Organizations Root ID."
  value       = one(aws_organizations_organization.this.roots).id
}
