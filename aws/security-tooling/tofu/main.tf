data "aws_caller_identity" "current" {}

locals {
  security_tooling_account_id = data.aws_caller_identity.current.account_id
  deployer_role_arn           = "arn:aws:iam::012646747332:role/deployer"
  state_admin_role_arn        = "arn:aws:iam::012646747332:role/tofu-state-admin"
  protected_state_bucket_arns = [
    "arn:aws:s3:::ghilbut-tfstates",
    "arn:aws:s3:::ghilbut-tfstates-v2",
  ]
  protected_state_object_arns = [for arn in local.protected_state_bucket_arns : "${arn}/*"]

  # Keep this list identical to foundation identity and SharedServices.
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
