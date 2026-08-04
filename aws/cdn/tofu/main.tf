locals {
  repo = "https://github.com/ghilbut/platform"

  fqdn_hosts = merge([
    for zone, hosts in var.zones : {
      for host, config in hosts : "${host}.${zone}" => config
    }
  ]...)

  fqdns = keys(local.fqdn_hosts)

  platform_certificate_fqdns = distinct(concat(local.fqdns, ["*.k3s.ghilbut.com"]))

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

module "tofu_execution_role" {
  source = "../../modules/tofu-execution-role"

  providers = { aws = aws.domains }

  name                       = "tofu-apply"
  description                = "OpenTofu execution role for Platform workload infrastructure."
  source_account_id          = "869061964712"
  source_permission_set_name = "TofuApplyForWorkloads"
  sso_region                 = "us-east-1"
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ])
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyCentralAdministration"
        Effect = "Deny"
        Action = [
          "account:*",
          "aws-portal:*",
          "billing:*",
          "budgets:*",
          "ce:*",
          "consolidatedbilling:*",
          "cur:*",
          "identitystore:*",
          "identitystore-auth:*",
          "identity-sync:*",
          "invoicing:*",
          "organizations:*",
          "payments:*",
          "purchase-orders:*",
          "sso:*",
          "sso-directory:*",
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyDomainsManagement"
        Effect   = "Deny"
        Action   = ["route53:*", "route53domains:*"]
        Resource = "*"
      },
    ]
  })
}

module "s3" {
  source = "./modules/s3"

  providers = { aws = aws.domains }

  # S3 bucket names share a global namespace, so include the repository owner.
  bucket_name = "${var.github_owner}-${var.name}"
  error_page_files = {
    "404.html" = "${path.root}/../404.html"
    "503.html" = "${path.root}/../503.html"
  }
  name = var.name
  repo = local.repo
}

module "certificate" {
  source = "./modules/certificate"

  providers = { aws = aws.domains }

  acm_domain_name = var.acm_domain_name
  fqdns           = local.fqdns
  name            = var.name
  repo            = local.repo
}

module "certificate_platform" {
  source = "./modules/certificate"

  providers = { aws = aws.platform }

  acm_domain_name = var.acm_domain_name
  fqdns           = local.platform_certificate_fqdns
  name            = "cdn-platform"
  repo            = local.repo
}

module "edge" {
  source = "./modules/edge"

  providers = { aws = aws.domains }

  allowlist          = local.viewer_request_allowlist
  bucket_arn         = module.s3.arn
  bucket_name        = module.s3.name
  name               = var.name
  redirect_map       = local.viewer_request_redirect_map
  repo               = local.repo
  spa_hosts          = local.viewer_request_spa_hosts
  lambda_source_file = "${path.root}/../lambda/dist/index.mjs"
}

module "cloudfront" {
  source = "./modules/cloudfront"

  providers = { aws = aws.domains }

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

  providers = { aws = aws.domains }

  bucket_arn                  = module.s3.arn
  bucket_name                 = module.s3.name
  cloudfront_distribution_arn = module.cloudfront.arn

  depends_on = [module.s3]
}

removed {
  from = module.dns

  lifecycle {
    destroy = false
  }
}

module "github_actions" {
  source = "./modules/github-actions"

  providers = { aws = aws.domains }

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
  state_bucket                     = "ghilbut-tfstates-v2"
  state_key                        = "platform/aws/cdn.tfstate"
}

removed {
  from = module.github_actions.github_actions_variable.cdn_role_arn

  lifecycle {
    destroy = false
  }
}
