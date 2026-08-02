module "vault" {
  source = "./modules/vault"

  name                      = "platform"
  oidc_issuer               = var.cpa_oidc_issuer
  service_account_name      = "vault"
  service_account_namespace = "vault"
}
