data "aws_caller_identity" "current" {}

locals {
  active_state_bucket_names  = ["ghilbut-tfstates"]
  cpa_oidc_issuer            = "https://oidc.k3s.ghilbut.com/cpa"
  shared_services_account_id = data.aws_caller_identity.current.account_id
  state_admin_role_arn       = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-state-admin"
  protected_state_bucket_arns = [
    "arn:aws:s3:::ghilbut-tfstates",
    "arn:aws:s3:::ghilbut-tfstates-v2",
  ]
  protected_state_object_arns = [for arn in local.protected_state_bucket_arns : "${arn}/*"]

  # Keep this list identical to foundation identity and SecurityTooling.
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
  url             = local.cpa_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["e7b8b5a6743ce1b2f17b041de59558a41472d70c"]
}
