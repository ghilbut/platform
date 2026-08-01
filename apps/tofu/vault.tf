resource "aws_kms_key" "vault" {
  description             = "Vault AWS KMS seal key"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "vault" {
  name          = "alias/platform-core-vault"
  target_key_id = aws_kms_key.vault.key_id
}
