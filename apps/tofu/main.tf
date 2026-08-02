module "vault" {
  source = "./modules/vault"

  name                      = "platform"
  oidc_issuer               = var.cpa_oidc_issuer
  service_account_name      = "vault"
  service_account_namespace = "vault"
}

locals {
  cert_manager_clusters = merge(
    {
      cpa = {
        hosted_zone_names         = ["ghilbut.com", "ghilbut.net"]
        oidc_issuer               = var.cpa_oidc_issuer
        service_account_name      = "cert-manager-dns01"
        service_account_namespace = "istio-gateways"
      }
    },
    var.cert_manager_clusters,
  )
}

module "cert_manager" {
  for_each = local.cert_manager_clusters

  source = "./modules/cert-manager"

  cluster_name              = each.key
  name                      = "platform"
  hosted_zone_names         = each.value.hosted_zone_names
  oidc_issuer               = each.value.oidc_issuer
  service_account_name      = each.value.service_account_name
  service_account_namespace = each.value.service_account_namespace
}
