data "aws_ssoadmin_instances" "current" {}

locals {
  instance_arn = tolist(data.aws_ssoadmin_instances.current.arns)[0]

  managed_policies = {
    AdministratorAccess        = "arn:aws:iam::aws:policy/AdministratorAccess"
    AWSOrganizationsFullAccess = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
  }

  account_assignments = {
    management_devops = {
      account_id     = "384959722788"
      principal_id   = "94183498-5041-705e-ddc0-aa6c2e714fbc"
      principal_type = "GROUP"
    }
    platform_ghilbut = {
      account_id     = "869061964712"
      principal_id   = "7488a448-2051-70eb-80b8-106a98d83549"
      principal_type = "USER"
    }
    ultary_domains_ghilbut = {
      account_id     = "971119963968"
      principal_id   = "7488a448-2051-70eb-80b8-106a98d83549"
      principal_type = "USER"
    }
  }
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
    "arn:aws:iam::aws:policy/Billing",
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
      principal_id   = "94183498-5041-705e-ddc0-aa6c2e714fbc"
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
  account_assignments = {
    platform = {
      account_id     = "869061964712"
      principal_id   = "7488a448-2051-70eb-80b8-106a98d83549"
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
      principal_id   = "7488a448-2051-70eb-80b8-106a98d83549"
      principal_type = "USER"
    }
  }
}
