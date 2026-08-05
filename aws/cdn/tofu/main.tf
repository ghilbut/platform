locals {
  repo = "https://github.com/ghilbut/platform"

  fqdn_hosts = merge([
    for zone, hosts in var.zones : {
      for host, config in hosts : "${host}.${zone}" => config
    }
  ]...)

  fqdns = keys(local.fqdn_hosts)

  # The wildcard SAN supports verification hostnames for future parallel distributions.
  certificate_fqdns = distinct(concat(local.fqdns, ["*.k3s.ghilbut.com"]))

  viewer_request_allowlist = keys(local.fqdn_hosts)
  viewer_request_redirect_map = {
    for fqdn, config in local.fqdn_hosts : fqdn => config.redirect_host
    if config.mode == "redirect"
  }
  viewer_request_spa_hosts = [
    for fqdn, config in local.fqdn_hosts : fqdn
    if config.mode == "spa"
  ]
}

module "certificate" {
  source = "./modules/certificate"

  acm_domain_name = var.acm_domain_name
  fqdns           = local.certificate_fqdns
  name            = var.name
  repo            = local.repo
}

module "s3" {
  source = "./modules/s3"

  bucket_name = "ghilbut-cdn-platform"
  error_page_files = {
    "404.html" = "${path.root}/../404.html"
    "503.html" = "${path.root}/../503.html"
  }
  name = var.name
  repo = local.repo
}

module "edge" {
  source = "./modules/edge"

  allowlist          = local.viewer_request_allowlist
  bucket_arn         = module.s3.arn
  bucket_name        = module.s3.name
  name               = var.name
  redirect_map       = local.viewer_request_redirect_map
  repo               = local.repo
  spa_hosts          = local.viewer_request_spa_hosts
  lambda_source_file = "${path.root}/../lambda/dist/index.mjs"

  lambda_source_contains_bucket_placeholder = true
}

module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_regional_domain_name = module.s3.regional_domain_name
  certificate_arn             = module.certificate.arn
  fqdns                       = local.fqdns
  lambda_function_arn         = module.edge.lambda_function_arn
  name                        = var.name
  repo                        = local.repo
  viewer_request_function_arn = module.edge.viewer_request_function_arn

  depends_on = [module.certificate]
}

module "origin_access" {
  source = "./modules/origin-access"

  bucket_arn                  = module.s3.arn
  bucket_name                 = module.s3.name
  cloudfront_distribution_arn = module.cloudfront.arn

  depends_on = [module.s3]
}

module "github_actions" {
  source = "./modules/github-actions"

  acm_certificate_arn              = module.certificate.arn
  cdn_bucket_arn                   = module.s3.arn
  cloudfront_distribution_arn      = module.cloudfront.arn
  cloudfront_function_arn          = module.edge.viewer_request_function_arn
  github_actions_oidc_provider_arn = data.terraform_remote_state.github.outputs.github_actions_oidc_provider_arn
  lambda_function_arn              = module.edge.lambda_function_base_arn
  lambda_role_arn                  = module.edge.lambda_role_arn
  name                             = var.name
  origin_access_control_arn        = module.cloudfront.origin_access_control_arn
  repository_full_name             = "${var.github_owner}/${var.github_repository}"
  repo                             = local.repo
  state_bucket                     = "ghilbut-tfstates"
  state_key                        = "platform/aws/cdn.tfstate"
}
