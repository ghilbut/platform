data "aws_ssoadmin_instances" "current" {}

data "terraform_remote_state" "accounts" {
  backend = "s3"

  config = {
    bucket = "ghilbut-tfstates"
    key    = "platform/aws/foundation/accounts.tfstate"
    region = "us-east-1"
  }
}

locals {
  instance_arn               = tolist(data.aws_ssoadmin_instances.current.arns)[0]
  identity_store_id          = tolist(data.aws_ssoadmin_instances.current.identity_store_ids)[0]
  ghilbut_user_id            = "7488a448-2051-70eb-80b8-106a98d83549"
  domains_account_id         = data.terraform_remote_state.accounts.outputs.domains_account_id
  shared_services_account_id = data.terraform_remote_state.accounts.outputs.shared_services_account_id
  state_buckets              = ["ghilbut-tfstates"]
  foundation_state_object_keys = [
    "platform/aws/foundation/accounts.tfstate",
    "platform/aws/foundation/accounts.tfstate.tflock",
    "platform/aws/foundation/identity.tfstate",
    "platform/aws/foundation/identity.tfstate.tflock",
    "platform/aws/foundation/organizations.tfstate",
    "platform/aws/foundation/organizations.tfstate.tflock",
  ]
  workload_accounts = {
    shared_services = {
      account_id          = local.shared_services_account_id
      tofu_apply_role_arn = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-apply"
      tofu_plan_role_arn  = "arn:aws:iam::${local.shared_services_account_id}:role/tofu-plan"
      state_object_keys = [
        "k3s.tfstate",
        "k3s.tfstate.tflock",
        "platform/apps.tfstate",
        "platform/apps.tfstate.tflock",
        "platform/aws/cdn.tfstate",
        "platform/aws/cdn.tfstate.tflock",
        "platform/aws/shared-services.tfstate",
        "platform/aws/shared-services.tfstate.tflock",
        "platform/github.tfstate",
        "platform/github.tfstate.tflock",
      ]
    }
  }
  workload_state_object_keys = sort(distinct(flatten([
    for account in values(local.workload_accounts) : account.state_object_keys
  ])))
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
      Sid      = "AssumeBillingRole"
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::384959722788:role/billing"
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
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.foundation_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
          ]
        ])
      },
      {
        Sid      = "FoundationStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "FoundationStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
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
  description  = "OpenTofu apply access for Domains DNS resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeDomainsExecutionRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${local.domains_account_id}:role/tofu-apply"
      },
      {
        Sid    = "DomainsStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.domains_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
          ]
        ])
      },
      {
        Sid      = "DomainsStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid    = "DomainsRemoteStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.domains_remote_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
          ]
        ])
      },
      {
        Sid      = "DomainsStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
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
        Sid      = "AssumeTofuExecutionRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = [for account in values(local.workload_accounts) : account.tofu_apply_role_arn]
      },
      {
        Sid    = "WorkloadStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.workload_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
          ]
        ])
      },
      {
        Sid      = "WorkloadStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "WorkloadStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
        Condition = {
          StringLike = {
            "s3:prefix" = local.workload_state_object_keys
          }
        }
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
        Sid    = "UltaryDomainsStateObjects"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.ultary_domains_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
          ]
        ])
      },
      {
        Sid      = "UltaryDomainsStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "UltaryDomainsStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
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

module "tofu_plan_for_management" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForManagement"
  description  = "OpenTofu plan access for Management account resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeTofuPlanRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::384959722788:role/tofu-plan"
      },
      {
        Sid    = "FoundationStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.foundation_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if !endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid    = "FoundationStateLocks"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.foundation_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid      = "FoundationStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "FoundationStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
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

module "tofu_plan_for_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForDomains"
  description  = "OpenTofu plan access for Domains DNS resources."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeDomainsPlanRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${local.domains_account_id}:role/tofu-plan"
      },
      {
        Sid    = "DomainsStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.domains_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if !endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid    = "DomainsStateLocks"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.domains_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid    = "DomainsRemoteStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.domains_remote_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
          ]
        ])
      },
      {
        Sid      = "DomainsStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "DomainsStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
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

module "tofu_plan_for_workloads" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "TofuPlanForWorkloads"
  description  = "OpenTofu plan access for workload infrastructure."
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AssumeTofuPlanRole"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = [for account in values(local.workload_accounts) : account.tofu_plan_role_arn]
      },
      {
        Sid    = "WorkloadStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.workload_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if !endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid    = "WorkloadStateLocks"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.workload_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid      = "WorkloadStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "WorkloadStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
        Condition = {
          StringLike = {
            "s3:prefix" = local.workload_state_object_keys
          }
        }
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
        Sid    = "UltaryDomainsStateObjects"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.ultary_domains_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if !endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid    = "UltaryDomainsStateLocks"
        Effect = "Allow"
        Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = flatten([
          for bucket in local.state_buckets : [
            for key in local.ultary_domains_state_object_keys : "arn:aws:s3:::${bucket}/${key}"
            if endswith(key, ".tflock")
          ]
        ])
      },
      {
        Sid      = "UltaryDomainsStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid      = "UltaryDomainsStateBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for bucket in local.state_buckets : "arn:aws:s3:::${bucket}"]
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
