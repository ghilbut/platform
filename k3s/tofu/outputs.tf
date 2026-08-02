output "cpa_oidc_issuer" {
  description = "Public OIDC issuer URL for the cpa K3S cluster"
  value       = module.cpa.issuer
}

output "cpa_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the cpa K3S cluster"
  value       = aws_iam_openid_connect_provider.cpa.arn
}
