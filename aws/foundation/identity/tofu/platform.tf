module "platform" {
  source = "./modules/permission-set"

  instance_arn = local.instance_arn
  name         = "platform-operator"
  description  = "Platform workload infrastructure administration."
  managed_policy_arns = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ])
  account_assignments = {
    platform = {
      account_id     = "869061964712"
      principal_id   = "7488a448-2051-70eb-80b8-106a98d83549"
      principal_type = "USER"
    }
  }
}
