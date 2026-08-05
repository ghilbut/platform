resource "aws_organizations_organization" "this" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "account.amazonaws.com",
    "sso.amazonaws.com",
  ]
  lifecycle {
    prevent_destroy = true
  }
}
