data "aws_caller_identity" "current" {}

locals {
  state_buckets = {
    primary = "ghilbut-tfstates"
  }
  management_account_id      = "384959722788"
  domains_account_id         = "869061964712"
  shared_services_account_id = data.aws_caller_identity.current.account_id
  ultary_account_id          = "971119963968"

  state_access = {
    management = {
      sid_prefix            = "Management"
      account_id            = local.management_account_id
      principal_arn_pattern = "arn:aws:iam::${local.management_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForManagement_*"
      object_keys = [
        "platform/aws/foundation/accounts.tfstate",
        "platform/aws/foundation/accounts.tfstate.tflock",
        "platform/aws/foundation/identity.tfstate",
        "platform/aws/foundation/identity.tfstate.tflock",
      ]
    }
    domains = {
      sid_prefix            = "Domains"
      account_id            = local.domains_account_id
      principal_arn_pattern = "arn:aws:iam::${local.domains_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForDomains_*"
      object_keys = [
        "platform/domains.tfstate",
        "platform/domains.tfstate.tflock",
      ]
      read_only_object_keys = [
        "platform/aws/cdn.tfstate",
      ]
    }
    shared_services = {
      sid_prefix            = "SharedServices"
      account_id            = local.shared_services_account_id
      principal_arn_pattern = "arn:aws:iam::${local.shared_services_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*"
      object_keys = [
        "k3s.tfstate",
        "k3s.tfstate.tflock",
        "platform/apps.tfstate",
        "platform/apps.tfstate.tflock",
        "platform/aws/cdn.tfstate",
        "platform/aws/cdn.tfstate.tflock",
        "platform/aws/platform.tfstate",
        "platform/aws/platform.tfstate.tflock",
        "platform/aws/shared-services.tfstate",
        "platform/aws/shared-services.tfstate.tflock",
        "platform/github.tfstate",
        "platform/github.tfstate.tflock",
      ]
    }
    ultary_domains = {
      sid_prefix            = "UltaryDomains"
      account_id            = local.ultary_account_id
      principal_arn_pattern = "arn:aws:iam::${local.ultary_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForUltaryDomains_*"
      object_keys = [
        "ultary/domains.tfstate",
        "ultary/domains.tfstate.tflock",
      ]
    }
  }

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
