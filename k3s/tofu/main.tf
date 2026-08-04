module "cpa" {
  source = "./modules/k3s"

  cdn_bucket      = var.cdn_bucket
  kubectl_context = "cpa"
  s3_prefix       = "oidc.k3s.ghilbut.com/cpa"
}

removed {
  from = aws_iam_openid_connect_provider.cpa

  lifecycle {
    destroy = false
  }
}
