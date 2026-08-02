module "ultary_domains" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "ultary-domains-operator"
  description  = "Ultary domain registration and Route 53 DNS administration."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
  ])
  account_assignments = {
    ultary_domains = {
      account_id     = "971119963968"
      principal_id   = "7488a448-2051-70eb-80b8-106a98d83549"
      principal_type = "USER"
    }
  }
}
