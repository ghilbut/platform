locals {
  state_object_keys = [
    "k3s.tfstate",
    "platform/apps.tfstate",
    "platform/aws/cdn.tfstate",
    "platform/aws/foundation/accounts.tfstate",
    "platform/aws/foundation/identity.tfstate",
    "platform/aws/foundation/organizations.tfstate",
    "platform/aws/security-tooling.tfstate",
    "platform/aws/shared-services.tfstate",
    "platform/domains.tfstate",
    "ultary/domains.tfstate",
  ]
  state_lock_object_keys = [for key in local.state_object_keys : "${key}.tflock"]
  state_bucket_arns      = [for bucket in values(local.state_buckets) : "arn:aws:s3:::${bucket}"]
  state_object_arns = flatten([
    for bucket in values(local.state_buckets) : [
      for key in local.state_object_keys : "arn:aws:s3:::${bucket}/${key}"
    ]
  ])
  state_lock_object_arns = flatten([
    for bucket in values(local.state_buckets) : [
      for key in local.state_lock_object_keys : "arn:aws:s3:::${bucket}/${key}"
    ]
  ])

  state_apply_source_principal_arn_patterns = [
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForDomains_*",
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForManagement_*",
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForUltaryDomains_*",
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*",
  ]
  deployer_role_arn = "arn:aws:iam::012646747332:role/deployer"
  state_readonly_source_principal_arn_patterns = [
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForDomains_*",
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForManagement_*",
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForUltaryDomains_*",
    "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForWorkloads_*",
  ]
}

resource "aws_iam_role" "tofu_state_apply" {
  name                 = "tofu-state-apply"
  description          = "OpenTofu backend state management role."
  max_session_duration = 14400

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowApplySourceIdentities"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-ncl6mypc8p"
          }
          ArnLike = {
            "aws:PrincipalArn" = local.state_apply_source_principal_arn_patterns
          }
        }
      },
      {
        Sid       = "AllowDeployer"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::012646747332:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = local.deployer_role_arn
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tofu_state_apply" {
  name = "tofu-state-apply-inline"
  role = aws_iam_role.tofu_state_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ManageStateObjects"
        Effect   = "Allow"
        Action   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = concat(local.state_object_arns, local.state_lock_object_arns)
      },
      {
        Sid      = "ReadStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = local.state_bucket_arns
      },
      {
        Sid      = "ListStateObjects"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.state_bucket_arns
        Condition = {
          StringLike = {
            "s3:prefix" = concat(local.state_object_keys, local.state_lock_object_keys)
          }
        }
      },
    ]
  })
}

resource "aws_iam_role" "tofu_state_readonly" {
  name                 = "tofu-state-readonly"
  description          = "Read-only OpenTofu backend state role with lock management."
  max_session_duration = 14400

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowPlanSourceIdentities"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-ncl6mypc8p"
          }
          ArnLike = {
            "aws:PrincipalArn" = concat(
              local.state_readonly_source_principal_arn_patterns,
              local.state_apply_source_principal_arn_patterns,
            )
          }
        }
      },
      {
        Sid       = "AllowDeployer"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::012646747332:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = local.deployer_role_arn
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tofu_state_readonly" {
  name = "tofu-state-readonly-inline"
  role = aws_iam_role.tofu_state_readonly.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadStateObjects"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = local.state_object_arns
      },
      {
        Sid      = "ManageStateLocks"
        Effect   = "Allow"
        Action   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
        Resource = local.state_lock_object_arns
      },
      {
        Sid      = "ReadStateBucketLocation"
        Effect   = "Allow"
        Action   = "s3:GetBucketLocation"
        Resource = local.state_bucket_arns
      },
      {
        Sid      = "ListStateObjects"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.state_bucket_arns
        Condition = {
          StringLike = {
            "s3:prefix" = concat(local.state_object_keys, local.state_lock_object_keys)
          }
        }
      },
    ]
  })
}
