resource "aws_s3_bucket" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  bucket        = each.value
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${each.value}",
      "arn:aws:s3:::${each.value}/*",
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
        for key in statement.value.object_keys : "arn:aws:s3:::${each.value}/${key}"
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
        for key in statement.value.read_only_object_keys : "arn:aws:s3:::${each.value}/${key}"
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
      resources = ["arn:aws:s3:::${each.value}"]

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
      resources = ["arn:aws:s3:::${each.value}"]

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

  dynamic "statement" {
    for_each = local.plan_state_access

    content {
      sid    = "AllowPlan${statement.value.sid_prefix}StateObjects"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions = ["s3:GetObject"]
      resources = [
        for key in statement.value.state_object_keys : "arn:aws:s3:::${each.value}/${key}"
      ]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }
    }
  }

  dynamic "statement" {
    for_each = local.plan_state_access

    content {
      sid    = "AllowPlan${statement.value.sid_prefix}LockObjects"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
      resources = [
        for key in statement.value.lock_object_keys : "arn:aws:s3:::${each.value}/${key}"
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
      for name, access in local.plan_state_access : name => access
      if length(try(access.read_only_object_keys, [])) > 0
    }

    content {
      sid    = "AllowPlan${statement.value.sid_prefix}RemoteStateObjects"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions = ["s3:GetObject"]
      resources = [
        for key in statement.value.read_only_object_keys : "arn:aws:s3:::${each.value}/${key}"
      ]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }
    }
  }

  dynamic "statement" {
    for_each = local.plan_state_access

    content {
      sid    = "AllowPlan${statement.value.sid_prefix}StateBucketLocation"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions   = ["s3:GetBucketLocation"]
      resources = ["arn:aws:s3:::${each.value}"]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }
    }
  }

  dynamic "statement" {
    for_each = local.plan_state_access

    content {
      sid    = "AllowPlan${statement.value.sid_prefix}StateBucketList"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account_id}:root"]
      }

      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${each.value}"]

      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = [statement.value.principal_arn_pattern]
      }

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values = concat(
          statement.value.state_object_keys,
          statement.value.lock_object_keys,
          try(statement.value.read_only_object_keys, []),
        )
      }
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  provider = aws.shared_services
  for_each = local.state_buckets

  bucket = aws_s3_bucket.state[each.key].id
  policy = data.aws_iam_policy_document.state[each.key].json
}
