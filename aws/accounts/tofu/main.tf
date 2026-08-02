resource "aws_organizations_account" "management" {
  name  = "management"
  email = "aws@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "platform" {
  name  = "platform"
  email = "aws-platform@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "ultary" {
  name  = "ultary-domains"
  email = "aws-ultary-domains@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

module "management" {
  source = "./modules/management"

  management_account_id = aws_organizations_account.management.id
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
