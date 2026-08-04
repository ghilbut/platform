output "role_arn" {
  description = "IAM role ARN assumed by cert-manager."
  value       = aws_iam_role.this.arn
}
