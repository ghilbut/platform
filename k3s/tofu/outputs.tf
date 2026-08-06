output "cpa_oidc_issuer" {
  description = "Public OIDC issuer URL for the cpa K3S cluster"
  value       = module.cpa.issuer
}

output "cpa_server_token" {
  description = "Password component of the CPA K3s server token."
  value = replace(
    random_password.cpa_server_token.result,
    "/^K10[0-9a-f]{64}::server:/",
    "",
  )
  sensitive = true
}
