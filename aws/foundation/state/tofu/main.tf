data "terraform_remote_state" "accounts" {
  backend = "s3"

  config = {
    bucket = "ghilbut-tfstates"
    key    = "platform/aws/foundation/accounts.tfstate"
    region = "us-east-1"
  }
}

locals {
  state_bucket                       = "ghilbut-tfstates"
  management_account_id              = "384959722788"
  management_source_role_arn_pattern = "arn:aws:iam::${local.management_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForManagement_*"
  platform_account_id                = data.terraform_remote_state.accounts.outputs.platform_account_id
  platform_source_role_arn_pattern   = "arn:aws:iam::${local.platform_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*"
  foundation_state_object_keys = [
    "platform/aws/foundation/accounts.tfstate",
    "platform/aws/foundation/accounts.tfstate.tflock",
    "platform/aws/foundation/identity.tfstate",
    "platform/aws/foundation/identity.tfstate.tflock",
  ]
  workload_state_object_keys = [
    "platform/aws/foundation/workload.tfstate",
    "platform/aws/foundation/workload.tfstate.tflock",
  ]
}

data "aws_iam_policy_document" "foundation_state_access" {
  statement {
    sid    = "AllowManagementFoundationStateObjects"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.management_account_id}:root"]
    }

    actions = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [
      for key in local.foundation_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.management_source_role_arn_pattern]
    }
  }

  statement {
    sid    = "AllowManagementFoundationStateBucketLocation"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.management_account_id}:root"]
    }

    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.management_source_role_arn_pattern]
    }

  }

  statement {
    sid    = "AllowManagementFoundationStateBucketList"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.management_account_id}:root"]
    }

    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.management_source_role_arn_pattern]
    }

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = local.foundation_state_object_keys
    }
  }

  statement {
    sid    = "AllowPlatformWorkloadStateObjects"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.platform_account_id}:root"]
    }

    actions = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [
      for key in local.workload_state_object_keys : "arn:aws:s3:::${local.state_bucket}/${key}"
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.platform_source_role_arn_pattern]
    }
  }

  statement {
    sid    = "AllowPlatformWorkloadStateBucketLocation"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.platform_account_id}:root"]
    }

    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.platform_source_role_arn_pattern]
    }
  }

  statement {
    sid    = "AllowPlatformWorkloadStateBucketList"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.platform_account_id}:root"]
    }

    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.platform_source_role_arn_pattern]
    }

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = local.workload_state_object_keys
    }
  }
}

resource "aws_s3_bucket_policy" "foundation_state_access" {
  bucket = local.state_bucket
  policy = data.aws_iam_policy_document.foundation_state_access.json
}
