data "terraform_remote_state" "accounts" {
  backend = "s3"

  config = {
    bucket = "ghilbut-tfstates"
    key    = "platform/aws/foundation/accounts.tfstate"
    region = "us-east-1"
  }
}

locals {
  platform_account_id = data.terraform_remote_state.accounts.outputs.platform_account_id
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

module "tofu_execution_role" {
  source = "../../../modules/tofu-execution-role"

  name                       = "tofu-apply"
  description                = "OpenTofu execution role for Platform workload infrastructure."
  source_account_id          = local.platform_account_id
  source_permission_set_name = "TofuApplyForWorkloads"
  sso_region                 = "us-east-1"
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyCentralAdministration"
      Effect   = "Deny"
      Action   = local.central_administration_denied_actions
      Resource = "*"
    }]
  })
}
