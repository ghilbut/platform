module "cpa" {
  source = "./modules/k3s"

  cdn_bucket      = aws_s3_bucket.this.id
  kubectl_context = "cpa"
  s3_prefix       = "oidc.k3s.ghilbut.com/cpa"
}
