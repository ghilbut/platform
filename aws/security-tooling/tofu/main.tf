data "aws_caller_identity" "current" {}

locals {
  security_tooling_account_id = data.aws_caller_identity.current.account_id
  deployer_role_arn           = "arn:aws:iam::012646747332:role/deployer"
  state_bucket_resources = [
    "arn:aws:s3:::ghilbut-tfstates",
    "arn:aws:s3:::ghilbut-tfstates-v2",
  ]
  state_object_resources = [for arn in local.state_bucket_resources : "${arn}/*"]

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
