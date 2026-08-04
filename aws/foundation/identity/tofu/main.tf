data "aws_ssoadmin_instances" "current" {}

data "terraform_remote_state" "accounts" {
  backend = "s3"

  config = {
    bucket = "ghilbut-tfstates-v2"
    key    = "platform/aws/foundation/accounts.tfstate"
    region = "us-east-1"
  }
}

locals {
  instance_arn        = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  identity_store_id   = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
  ghilbut_user_id     = "7488a448-2051-70eb-80b8-106a98d83549"
  domains_account_id  = data.terraform_remote_state.accounts.outputs.domains_account_id
  platform_account_id = data.terraform_remote_state.accounts.outputs.platform_account_id
  state_bucket        = "ghilbut-tfstates-v2"
  foundation_state_object_keys = [
    "platform/aws/foundation/accounts.tfstate",
    "platform/aws/foundation/accounts.tfstate.tflock",
    "platform/aws/foundation/identity.tfstate",
    "platform/aws/foundation/identity.tfstate.tflock",
  ]
  platform_state_object_keys = [
    "platform/aws/foundation/state.tfstate",
    "platform/aws/foundation/state.tfstate.tflock",
    "platform/aws/foundation/workload.tfstate",
    "platform/aws/foundation/workload.tfstate.tflock",
  ]
  domains_state_object_keys = [
    "platform/domains.tfstate",
    "platform/domains.tfstate.tflock",
  ]
  domains_remote_state_object_keys = [
    "platform/aws/cdn.tfstate",
  ]
  ultary_domains_state_object_keys = [
    "ultary/domains.tfstate",
    "ultary/domains.tfstate.tflock",
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
  name         = "FoundationManagement"
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
        Sid    = "FoundationStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = [
          for key in local.foundation_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
        ]
      },
      {
        Sid      = "FoundationStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = "arn:aws:s3:::${local.state_bucket}"
      },
      {
        Sid      = "FoundationStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.state_bucket}"
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
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DomainsStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = [
          for key in local.domains_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
        ]
      },
      {
        Sid      = "DomainsStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = "arn:aws:s3:::${local.state_bucket}"
      },
      {
        Sid    = "DomainsRemoteStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = [
          for key in local.domains_remote_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
        ]
      },
      {
        Sid      = "DomainsStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.state_bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = concat(local.domains_state_object_keys, local.domains_remote_state_object_keys)
          }
        }
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
        Sid    = "AssumeTofuExecutionRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${local.domains_account_id}:role/tofu-apply",
          "arn:aws:iam::${local.platform_account_id}:role/tofu-apply",
        ]
      },
      {
        Sid    = "WorkloadStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = [
          for key in local.platform_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
        ]
      },
      {
        Sid      = "WorkloadStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = "arn:aws:s3:::${local.state_bucket}"
      },
      {
        Sid      = "WorkloadStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.state_bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = local.platform_state_object_keys
          }
        }
      },
    ]
  })
  account_assignments = {
    domains = {
      account_id     = local.domains_account_id
      principal_id   = aws_identitystore_group.devops.group_id
      principal_type = "GROUP"
    }
    platform = {
      account_id     = local.platform_account_id
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
        Sid    = "UltaryDomainsStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = [
          for key in local.ultary_domains_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
        ]
      },
      {
        Sid      = "UltaryDomainsStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = "arn:aws:s3:::${local.state_bucket}"
      },
      {
        Sid      = "UltaryDomainsStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${local.state_bucket}"
        Condition = {
          StringLike = {
            "s3:prefix" = local.ultary_domains_state_object_keys
          }
        }
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
