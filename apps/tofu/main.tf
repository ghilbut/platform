resource "aws_iam_openid_connect_provider" "cpa" {
  url             = var.cpa_oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.cpa_oidc_thumbprint]
}

module "vault" {
  source = "./modules/vault"

  name                      = "platform"
  oidc_issuer               = var.cpa_oidc_issuer
  oidc_provider_arn         = aws_iam_openid_connect_provider.cpa.arn
  service_account_name      = "vault"
  service_account_namespace = "vault"
}
