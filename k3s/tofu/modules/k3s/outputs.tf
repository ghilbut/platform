output "issuer" {
  description = "Public OIDC issuer URL"
  value       = "https://${var.s3_prefix}"
}
