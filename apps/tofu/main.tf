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
  source = "./modules/cert-manager"

  clusters = local.cert_manager_clusters
  name     = "platform"
}

locals {
  external_dns_clusters = merge(
    {
      cpa = {
        hosted_zone_names         = ["ghilbut.com", "ghilbut.net"]
        oidc_issuer               = var.cpa_oidc_issuer
        record_names              = ["id.ghilbut.com", "vault.ghilbut.com"]
        service_account_name      = "external-dns"
        service_account_namespace = "external-dns"
        txt_prefix                = "external-dns-"
      }
    },
    var.external_dns_clusters,
  )
}

module "external_dns" {
  source = "./modules/external-dns"

  clusters = local.external_dns_clusters
  name     = "platform"
}
