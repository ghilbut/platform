locals {
  disabled_opt_in_regions = toset([
    "af-south-1",
    "ap-east-1",
    "ap-east-2",
    "ap-south-2",
    "ap-southeast-3",
    "ap-southeast-4",
    "ap-southeast-5",
    "ap-southeast-6",
    "ap-southeast-7",
    "ca-west-1",
    "eu-central-2",
    "eu-south-1",
    "eu-south-2",
    "il-central-1",
    "me-central-1",
    "me-south-1",
    "mx-central-1",
  ])
}

module "management" {
  source = "./modules/account-regions"

  disabled_opt_in_regions = local.disabled_opt_in_regions
}

module "security_tooling_regions" {
  source = "./modules/account-regions"

  account_id              = aws_organizations_account.security_tooling.id
  disabled_opt_in_regions = local.disabled_opt_in_regions
}
