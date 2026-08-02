resource "aws_kms_key" "seal" {
  description             = "Vault AWS KMS seal key"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "seal" {
  name          = "alias/${var.name}-vault"
  target_key_id = aws_kms_key.seal.key_id
}

locals {
  oidc_condition_prefix = trimprefix(var.oidc_issuer, "https://")
}

resource "aws_iam_role" "vault" {
  name = "${var.name}-vault"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = var.oidc_provider_arn }
        Condition = {
          StringEquals = {
            "${local.oidc_condition_prefix}:aud" = "sts.amazonaws.com"
            "${local.oidc_condition_prefix}:sub" = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "kms_seal" {
  name = "${var.name}-vault-kms-seal"
  role = aws_iam_role.vault.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UseVaultKmsSealKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
        ]
        Resource = aws_kms_key.seal.arn
      },
    ]
  })
}
