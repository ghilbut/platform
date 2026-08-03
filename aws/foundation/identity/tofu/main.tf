data "aws_ssoadmin_instances" "current" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
  ghilbut_user_id   = "7488a448-2051-70eb-80b8-106a98d83549"

  managed_policies = {
    AdministratorAccess        = "arn:aws:iam::aws:policy/AdministratorAccess"
    AWSOrganizationsFullAccess = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
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

  account_assignments = {
    management_devops = {
      account_id     = "384959722788"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
    platform_ghilbut = {
      account_id     = "869061964712"
      principal_id   = local.ghilbut_user_id
      principal_type = "USER"
    }
    ultary_domains_ghilbut = {
      account_id     = "971119963968"
      principal_id   = local.ghilbut_user_id
      principal_type = "USER"
    }
  }
}

resource "aws_identitystore_group" "devops" {
  display_name      = "DevOps"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group_membership" "devops_ghilbut" {
  group_id          = aws_identitystore_group.devops.group_id
  identity_store_id = local.identity_store_id
  member_id         = local.ghilbut_user_id
}

resource "aws_ssoadmin_permission_set" "tofu" {
  instance_arn     = local.instance_arn
  name             = "tofu"
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "tofu" {
  for_each = local.managed_policies

  instance_arn       = local.instance_arn
  managed_policy_arn = each.value
  permission_set_arn = aws_ssoadmin_permission_set.tofu.arn
}

resource "aws_ssoadmin_account_assignment" "tofu" {
  for_each = local.account_assignments

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.tofu.arn
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
  target_id          = each.value.account_id
  target_type        = "AWS_ACCOUNT"
}

module "management" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "foundation-management"
  description  = "AWS Organizations, account, billing, and IAM Identity Center administration."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess",
    "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator",
    "arn:aws:iam::aws:policy/job-function/Billing",
    "arn:aws:iam::aws:policy/IAMFullAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "AccountManagement"
      Effect   = "Allow"
      Action   = "account:*"
      Resource = "*"
    }]
  })
  account_assignments = {
    management = {
      account_id     = "384959722788"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "platform" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "platform-operator"
  description  = "Platform workload infrastructure administration."
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
  account_assignments = {
    platform = {
      account_id     = "869061964712"
      principal_id   = local.ghilbut_user_id
      principal_type = "USER"
    }
  }
}

module "ultary_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "ultary-domains-operator"
  description  = "Ultary domain registration and Route 53 DNS administration."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
  ])
  account_assignments = {
    ultary_domains = {
      account_id     = "971119963968"
      principal_id   = local.ghilbut_user_id
      principal_type = "USER"
    }
  }
}

module "management_tofu_apply" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "ManagementTofuApply"
  description  = "OpenTofu apply access for Foundation management-account resources."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess",
    "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator",
    "arn:aws:iam::aws:policy/IAMFullAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AccountRegionManagement"
      Effect = "Allow"
      Action = [
        "account:DisableRegion",
        "account:EnableRegion",
        "account:GetRegionOptStatus",
        "account:ListRegions",
      ]
      Resource = "*"
    }]
  })
  account_assignments = {
    management = {
      account_id     = "384959722788"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_apply" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuApply"
  description  = "OpenTofu apply access for Platform workload infrastructure."
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
  account_assignments = {
    platform = {
      account_id     = "869061964712"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "ultary_domains_tofu_apply" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "UltaryDomainsTofuApply"
  description  = "OpenTofu apply access for Ultary domain and Route 53 resources."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
  ])
  account_assignments = {
    ultary_domains = {
      account_id     = "971119963968"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}
