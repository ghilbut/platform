resource "aws_organizations_organization" "this" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "account.amazonaws.com",
    "sso.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = one(aws_organizations_organization.this.roots).id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy" "member_account_protection" {
  name        = "ProtectMemberAccounts"
  description = "Prevents member accounts from leaving the organization or closing their AWS account."
  type        = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyLeaveOrganizationAndCloseAccount"
      Effect = "Deny"
      Action = [
        "account:CloseAccount",
        "organizations:LeaveOrganization",
      ]
      Resource = "*"
    }]
  })

  depends_on = [aws_organizations_organization.this]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_policy_attachment" "member_account_protection" {
  policy_id = aws_organizations_policy.member_account_protection.id
  target_id = one(aws_organizations_organization.this.roots).id

  lifecycle {
    prevent_destroy = true
  }
}
