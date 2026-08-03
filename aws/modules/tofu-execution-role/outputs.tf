output "arn" {
  description = "생성한 IAM 실행 역할 ARN입니다."
  value       = aws_iam_role.this.arn
}
