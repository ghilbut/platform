locals {
  cpa_oidc_issuer               = "https://oidc.k3s.ghilbut.com/cpa"
  cpa_oidc_provider_path        = trimprefix(local.cpa_oidc_issuer, "https://")
  vault_service_account_subject = "system:serviceaccount:vault:vault"
}

resource "aws_iam_openid_connect_provider" "cpa" {
  url             = local.cpa_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.cpa_oidc_thumbprint]
}

data "aws_iam_policy_document" "vault_unseal_assume" {
  statement {
    sid     = "AllowCpaVaultServiceAccount"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cpa.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.cpa_oidc_provider_path}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.cpa_oidc_provider_path}:sub"
      values   = [local.vault_service_account_subject]
    }
  }
}

resource "aws_iam_role" "vault_unseal" {
  name                 = "vault-cpa-unseal"
  description          = "AWS KMS auto-unseal role for the CPA Vault server."
  max_session_duration = 3600
  assume_role_policy   = data.aws_iam_policy_document.vault_unseal_assume.json

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "vault_unseal_key" {
  statement {
    sid    = "AllowOpenTofuKeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.tofu_apply.arn]
    }

    actions = [
      "kms:CancelKeyDeletion",
      "kms:Create*",
      "kms:Delete*",
      "kms:Describe*",
      "kms:Disable*",
      "kms:Enable*",
      "kms:Get*",
      "kms:List*",
      "kms:Put*",
      "kms:Revoke*",
      "kms:RotateKeyOnDemand",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:Update*",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowOpenTofuKeyInspection"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.tofu_plan.arn]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowVaultSealOperations"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.vault_unseal.arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "vault_unseal" {
  description             = "CPA Vault auto-unseal key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_unseal_key.json

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/vault-cpa-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

data "aws_iam_policy_document" "vault_unseal" {
  statement {
    sid    = "UseVaultUnsealKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
    ]
    resources = [aws_kms_key.vault_unseal.arn]
  }
}

resource "aws_iam_role_policy" "vault_unseal" {
  name   = "vault-cpa-unseal"
  role   = aws_iam_role.vault_unseal.name
  policy = data.aws_iam_policy_document.vault_unseal.json
}
