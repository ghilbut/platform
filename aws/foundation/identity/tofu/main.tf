data "aws_ssoadmin_instances" "current" {}

data "terraform_remote_state" "accounts" {
  backend = "s3"

  config = {
    bucket = "ghilbut-tfstates"
    key    = "platform/aws/foundation/accounts.tfstate"
    region = "us-east-1"
    assume_role = {
      role_arn = "arn:aws:iam::012646747332:role/tofu-state-readonly"
    }
  }
}

locals {
  instance_arn                = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  identity_store_id           = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
  ghilbut_user_id             = "7488a448-2051-70eb-80b8-106a98d83549"
  domains_account_id          = data.terraform_remote_state.accounts.outputs.domains_account_id
  security_tooling_account_id = data.terraform_remote_state.accounts.outputs.security_tooling_account_id
  shared_services_account_id  = data.terraform_remote_state.accounts.outputs.shared_services_account_id
  state_admin_role_arn        = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-state-admin"
  state_apply_role_arn        = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-state-apply"
  state_readonly_role_arn     = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-state-readonly"
  # Bucket and object ARNs denied to OpenTofu source identities.
  state_bucket_resources = [
    "arn:aws:s3:::ghilbut-tfstates",
    "arn:aws:s3:::ghilbut-tfstates/*",
    "arn:aws:s3:::ghilbut-tfstates-v2",
    "arn:aws:s3:::ghilbut-tfstates-v2/*",
  ]
  workload_accounts = {
    security_tooling = {
      account_id          = local.security_tooling_account_id
      tofu_apply_role_arn = "arn:aws:iam::${local.security_tooling_account_id}:role/tofu-apply"
      tofu_plan_role_arn  = "arn:aws:iam::${local.security_tooling_account_id}:role/tofu-plan"
    }
    shared_services = {
      account_id          = local.shared_services_account_id
      tofu_apply_role_arn = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-apply"
      tofu_plan_role_arn  = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-plan"
    }
  }

  # Keep this list identical to SharedServices and SecurityTooling.
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

resource "aws_identitystore_group" "devops" {
  display_name      = "DevOps"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group_membership" "devops_ghilbut" {
  group_id          = aws_identitystore_group.devops.group_id
  identity_store_id = local.identity_store_id
  member_id         = local.ghilbut_user_id
}

module "management" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "FoundationManagement"
  description  = "AWS Organizations, account, and IAM Identity Center administration."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess",
    "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator",
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

module "billing" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "Billing"
  description  = "Billing and cost management access for the Management account."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/job-function/Billing",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ViewCostExplorerReports"
      Effect   = "Allow"
      Action   = "ce:DescribeReport"
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

module "backup_recovery" {
  source = "./modules/permission-set"

  instance_arn     = local.instance_arn
  name             = "BackupRecovery"
  description      = "Read-only access to platform recovery backups."
  session_duration = "PT1H"
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadBackupBucketConfiguration"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
        ]
        Resource = "arn:aws:s3:::ghilbut-backups"
      },
      {
        Sid    = "ListCpaSnapshots"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
        ]
        Resource = "arn:aws:s3:::ghilbut-backups"
        Condition = {
          StringLikeIfExists = {
            "s3:prefix" = [
              "k3s/cpa",
              "k3s/cpa/*",
            ]
          }
        }
      },
      {
        Sid    = "ReadCpaSnapshots"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "arn:aws:s3:::ghilbut-backups/k3s/cpa/*"
      },
    ]
  })
  account_assignments = {
    shared_services = {
      account_id     = local.shared_services_account_id
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_apply_for_management" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuApplyForManagement"
  description  = "OpenTofu apply access for Management account resources."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess",
    "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator",
    "arn:aws:iam::aws:policy/IAMFullAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccountRegionManagement"
        Effect = "Allow"
        Action = [
          "account:DisableRegion",
          "account:EnableRegion",
          "account:GetRegionOptStatus",
          "account:ListRegions",
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeTofuExecutionRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::384959722788:role/tofu-apply",
          local.state_apply_role_arn,
          local.state_readonly_role_arn,
        ]
      },
    ]
  })
  account_assignments = {
    management = {
      account_id     = "384959722788"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_apply_for_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuApplyForDomains"
  description  = "OpenTofu apply access for Domains DNS resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeDomainsExecutionRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${local.domains_account_id}:role/tofu-apply",
          local.state_apply_role_arn,
          local.state_readonly_role_arn,
        ]
      },
    ]
  })
  account_assignments = {
    domains = {
      account_id     = local.domains_account_id
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_apply_for_workloads" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuApplyForWorkloads"
  description  = "Source access to workload OpenTofu apply execution roles."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyCentralAdministration"
        Effect   = "Deny"
        Action   = local.central_administration_denied_actions
        Resource = "*"
      },
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeTofuExecutionRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = concat(
          [for account in values(local.workload_accounts) : account.tofu_apply_role_arn],
          [local.state_admin_role_arn, local.state_apply_role_arn, local.state_readonly_role_arn],
        )
      },
    ]
  })
  account_assignments = {
    for name, account in local.workload_accounts : name => {
      account_id     = account.account_id
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_apply_for_ultary_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuApplyForUltaryDomains"
  description  = "OpenTofu apply access for Ultary Domains Route 53 resources."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeStateRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          local.state_apply_role_arn,
          local.state_readonly_role_arn,
        ]
      },
    ]
  })
  account_assignments = {
    ultary_domains = {
      account_id     = "971119963968"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_plan_for_management" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForManagement"
  description  = "OpenTofu plan access for Management account resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeTofuPlanRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::384959722788:role/tofu-plan",
          local.state_readonly_role_arn,
        ]
      },
    ]
  })
  account_assignments = {
    management = {
      account_id     = "384959722788"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_plan_for_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForDomains"
  description  = "OpenTofu plan access for Domains DNS resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeDomainsPlanRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${local.domains_account_id}:role/tofu-plan",
          local.state_readonly_role_arn,
        ]
      },
    ]
  })
  account_assignments = {
    domains = {
      account_id     = local.domains_account_id
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_plan_for_workloads" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForWorkloads"
  description  = "Source access to workload OpenTofu plan execution roles."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid    = "AssumeTofuPlanRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = concat(
          [for account in values(local.workload_accounts) : account.tofu_plan_role_arn],
          [local.state_readonly_role_arn],
        )
      },
    ]
  })
  account_assignments = {
    for name, account in local.workload_accounts : name => {
      account_id     = account.account_id
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_plan_for_ultary_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForUltaryDomains"
  description  = "OpenTofu plan access for Ultary Domains Route 53 resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UltaryDomainsRead"
        Effect = "Allow"
        Action = [
          "route53:Get*",
          "route53:List*",
          "route53:TestDNSAnswer",
          "route53domains:Check*",
          "route53domains:Get*",
          "route53domains:List*",
          "route53domains:View*",
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = local.state_bucket_resources
      },
      {
        Sid      = "AssumeStateRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = local.state_readonly_role_arn
      },
    ]
  })
  account_assignments = {
    ultary_domains = {
      account_id     = "971119963968"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}
