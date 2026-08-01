resource "aws_kms_key" "vault" {
  description             = "Vault AWS KMS seal key"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.name}-vault"
  target_key_id = aws_kms_key.vault.key_id
}

resource "aws_iam_role_policy" "vault_kms_seal" {
  name = "${var.name}-vault-kms-seal"
  role = module.awsra.role_name

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
        Resource = aws_kms_key.vault.arn
      },
    ]
  })
}
