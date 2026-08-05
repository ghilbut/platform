data "aws_caller_identity" "current" {}

locals {
  platform_account_id = data.aws_caller_identity.current.account_id
  central_administration_denied_actions = [
    "account:*",
    "aws-portal:*",
    "billing:*",
    "budgets:*",
    "ce:*",
    "consolidatedbilling:*",
    "cur:*",
    "identitystore:*",
    "identitystore-auth:*",
    "identity-sync:*",
    "invoicing:*",
    "organizations:*",
    "payments:*",
    "purchase-orders:*",
    "sso:*",
    "sso-directory:*",
  ]
}

resource "aws_iam_openid_connect_provider" "cpa" {
  url             = "https://oidc.k3s.ghilbut.com/cpa"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.cpa_oidc_thumbprint]
}
