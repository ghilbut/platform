output "github_actions_oidc_provider_arn" {
  description = "ARN of the Platform GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
