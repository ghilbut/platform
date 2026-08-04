locals {
  state_bucket          = "ghilbut-tfstates-v2"
  management_account_id = "384959722788"
  domains_account_id    = "869061964712"
  platform_account_id   = "012646747332"
  ultary_account_id     = "971119963968"

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
    domains_workloads = {
      sid_prefix            = "DomainsWorkloads"
      account_id            = local.domains_account_id
      principal_arn_pattern = "arn:aws:iam::${local.domains_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*"
      object_keys = [
        "k3s.tfstate",
        "k3s.tfstate.tflock",
        "platform/apps.tfstate",
        "platform/apps.tfstate.tflock",
        "platform/aws/cdn.tfstate",
        "platform/aws/cdn.tfstate.tflock",
        "platform/domains.tfstate",
        "platform/domains.tfstate.tflock",
        "platform/github.tfstate",
        "platform/github.tfstate.tflock",
        "ultary/domains.tfstate",
        "ultary/domains.tfstate.tflock",
      ]
    }
    domains_cdn_github_actions = {
      sid_prefix            = "DomainsCdnGitHubActions"
      account_id            = local.domains_account_id
      principal_arn_pattern = "arn:aws:iam::${local.domains_account_id}:role/platform-cdn-github-actions"
      object_keys = [
        "platform/aws/cdn.tfstate",
        "platform/aws/cdn.tfstate.tflock",
      ]
    }
    platform = {
      sid_prefix            = "Platform"
      account_id            = local.platform_account_id
      principal_arn_pattern = "arn:aws:iam::${local.platform_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*"
      object_keys = [
        "k3s.tfstate",
        "k3s.tfstate.tflock",
        "platform/apps.tfstate",
        "platform/apps.tfstate.tflock",
        "platform/aws/cdn.tfstate",
        "platform/aws/cdn.tfstate.tflock",
        "platform/aws/foundation/state.tfstate",
        "platform/aws/foundation/state.tfstate.tflock",
        "platform/aws/foundation/workload.tfstate",
        "platform/aws/foundation/workload.tfstate.tflock",
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
}

resource "aws_s3_bucket" "state" {
  bucket        = local.state_bucket
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "state" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  dynamic "statement" {
    for_each = local.state_access

    content {
      sid    = "Allow${statement.value.sid_prefix}StateObjects"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
      resources = [
        for key in statement.value.object_keys : "${aws_s3_bucket.state.arn}/${key}"
      ]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }
    }
  }

  dynamic "statement" {
    for_each = {
      for name, access in local.state_access : name => access
      if length(try(access.read_only_object_keys, [])) > 0
    }

    content {
      sid    = "Allow${statement.value.sid_prefix}RemoteStateObjects"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions = ["s3:GetObject"]
      resources = [
        for key in statement.value.read_only_object_keys : "${aws_s3_bucket.state.arn}/${key}"
      ]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }
    }
  }

  dynamic "statement" {
    for_each = local.state_access

    content {
      sid    = "Allow${statement.value.sid_prefix}StateBucketLocation"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions   = ["s3:GetBucketLocation"]
      resources = [aws_s3_bucket.state.arn]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }
    }
  }

  dynamic "statement" {
    for_each = local.state_access

    content {
      sid    = "Allow${statement.value.sid_prefix}StateBucketList"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions   = ["s3:ListBucket"]
      resources = [aws_s3_bucket.state.arn]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = concat(statement.value.object_keys, try(statement.value.read_only_object_keys, []))
      }
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
