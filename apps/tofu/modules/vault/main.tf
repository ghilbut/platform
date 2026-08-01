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

resource "aws_iam_role_policy" "kms_seal" {
  name = "${var.name}-vault-kms-seal"
  role = var.awsra_role_name

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

resource "local_file" "manifest" {
  filename = "${var.manifest_directory_path}/vault-cm.yaml"

  content = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "vault"
      namespace = "vault"
    }
    data = {
      VAULT_AWSKMS_SEAL_KEY_ID = aws_kms_alias.seal.name
    }
  })
}
