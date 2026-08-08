locals {
  cpa_snapshot_prefix                  = "k3s/cpa"
  vault_backup_prefix                  = "vault/cpa/raft"
  vault_backup_service_account_subject = "system:serviceaccount:vault:vault-backup"
}

resource "aws_s3_bucket" "backups" {
  bucket        = "ghilbut-backups"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "cpa-snapshot-recovery-window"
    status = "Enabled"

    filter {
      prefix = "${local.cpa_snapshot_prefix}/"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.backups]
}

data "aws_iam_policy_document" "backups_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.backups.arn,
      "${aws_s3_bucket.backups.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "backups" {
  bucket = aws_s3_bucket.backups.id
  policy = data.aws_iam_policy_document.backups_bucket.json
}

resource "aws_iam_user" "cpa_snapshot" {
  name          = "k3s-cpa-snapshot"
  force_destroy = false
}

data "aws_iam_policy_document" "cpa_snapshot" {
  statement {
    sid       = "ReadBackupBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.backups.arn]
  }

  statement {
    sid       = "ListCpaSnapshots"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backups.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.cpa_snapshot_prefix,
        "${local.cpa_snapshot_prefix}/*",
      ]
    }
  }

  statement {
    sid    = "ManageCpaSnapshots"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.backups.arn}/${local.cpa_snapshot_prefix}/*"]
  }
}

resource "aws_iam_user_policy" "cpa_snapshot" {
  name   = "k3s-cpa-snapshot"
  user   = aws_iam_user.cpa_snapshot.name
  policy = data.aws_iam_policy_document.cpa_snapshot.json
}

data "aws_iam_policy_document" "vault_backup_assume" {
  statement {
    sid     = "AllowCpaVaultBackupServiceAccount"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cpa.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(local.cpa_oidc_issuer, "https://")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${trimprefix(local.cpa_oidc_issuer, "https://")}:sub"
      values   = [local.vault_backup_service_account_subject]
    }
  }
}

resource "aws_iam_role" "vault_backup" {
  name                 = "vault-cpa-backup"
  description          = "CPA Vault Raft snapshot writer for the platform backup bucket."
  max_session_duration = 3600
  assume_role_policy   = data.aws_iam_policy_document.vault_backup_assume.json

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "vault_backup" {
  statement {
    sid       = "ReadBackupBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [aws_s3_bucket.backups.arn]
  }

  statement {
    sid       = "ListVaultBackups"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.backups.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.vault_backup_prefix,
        "${local.vault_backup_prefix}/*",
      ]
    }
  }

  statement {
    sid    = "ManageVaultBackups"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.backups.arn}/${local.vault_backup_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "vault_backup" {
  name   = "vault-cpa-backup"
  role   = aws_iam_role.vault_backup.name
  policy = data.aws_iam_policy_document.vault_backup.json
}
