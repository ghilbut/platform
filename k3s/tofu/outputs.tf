output "cpa_oidc_issuer" {
  description = "Public OIDC issuer URL for the cpa K3S cluster"
  value       = module.cpa.issuer
}
