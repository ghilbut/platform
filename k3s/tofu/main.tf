module "cpa" {
  source = "./modules/k3s"

  cdn_bucket      = var.cdn_bucket
  kubectl_context = "cpa"
  s3_prefix       = "oidc.k3s.ghilbut.com/cpa"
}

resource "aws_iam_openid_connect_provider" "cpa" {
  url             = module.cpa.issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.cpa_oidc_thumbprint]
}
