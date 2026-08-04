data "aws_ssoadmin_instances" "current" {}

locals {
  instance_arn            = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  identity_store_id       = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
  ghilbut_user_id         = "7488a448-2051-70eb-80b8-106a98d83549"
  foundation_state_bucket = "ghilbut-tfstates"
  foundation_state_object_keys = [
    "platform/aws/foundation/accounts.tfstate",
    "platform/aws/foundation/accounts.tfstate.tflock",
    "platform/aws/foundation/identity.tfstate",
    "platform/aws/foundation/identity.tfstate.tflock",
  ]

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

module "management_tofu_execution_role" {
  source = "../../../modules/tofu-execution-role"

  name                       = "tofu-apply"
  description                = "OpenTofu execution role for Foundation management-account resources."
  source_account_id          = "384959722788"
  source_permission_set_name = "TofuApplyForManagement"
  sso_region                 = "us-east-1"
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
        Sid      = "AssumeTofuExecutionRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::384959722788:role/tofu-apply"
      },
      {
        Sid      = "FoundationStateObjects"
        Effect   = "Allow"
        Action   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = [for key in local.foundation_state_object_keys : "arn:aws:s3:::${local.foundation_state_bucket}/${key}"]
      },
      {
        Sid      = "FoundationStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = "arn:aws:s3:::${local.foundation_state_bucket}"
      },
      {
        Sid      = "FoundationStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.foundation_state_bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = local.foundation_state_object_keys
          }
        }
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
  description  = "OpenTofu apply access for Domains account Route 53 resources."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
  ])
  account_assignments = {
    platform = {
      account_id     = "869061964712"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}

module "tofu_apply_for_workloads" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuApplyForWorkloads"
  description  = "OpenTofu apply access for workload infrastructure."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ])
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
        Sid      = "AssumeTofuExecutionRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::869061964712:role/tofu-apply"
      },
    ]
  })
  account_assignments = {
    platform = {
      account_id     = "869061964712"
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
  account_assignments = {
    ultary_domains = {
      account_id     = "971119963968"
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
  }
}
