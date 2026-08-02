output "permission_set_arn" {
  description = "생성한 IAM Identity Center permission set ARN입니다."
  value       = aws_ssoadmin_permission_set.this.arn
}
