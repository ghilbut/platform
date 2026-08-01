output "kms_key_arn" {
  description = "KMS key ARN for Vault's AWS KMS seal configuration."
  value       = aws_kms_key.seal.arn
}
