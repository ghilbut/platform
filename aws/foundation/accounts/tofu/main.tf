data "terraform_remote_state" "organizations" {
  backend = "s3"

  config = {
    bucket = "ghilbut-tfstates"
    key    = "platform/aws/foundation/organizations.tfstate"
    region = "us-east-1"
  }
}

locals {
  organization_root_id = data.terraform_remote_state.organizations.outputs.root_id
  infrastructure_ou_id = data.terraform_remote_state.organizations.outputs.infrastructure_ou_id
  security_ou_id       = data.terraform_remote_state.organizations.outputs.security_ou_id
}

resource "aws_organizations_account" "management" {
  name      = "Management"
  email     = "aws@ghilbut.com"
  parent_id = local.organization_root_id

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "domains" {
  name      = "Domains"
  email     = "aws-domains@ghilbut.com"
  parent_id = local.infrastructure_ou_id

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "shared_services" {
  name      = "SharedServices"
  email     = "aws-platform@ghilbut.com"
  parent_id = local.infrastructure_ou_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "security_tooling" {
  name      = "SecurityTooling"
  email     = "aws-security-tooling@ghilbut.com"
  parent_id = local.security_ou_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "ultary" {
  name      = "UltaryDomains"
  email     = "aws-ultary-domains@ghilbut.com"
  parent_id = local.organization_root_id

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}
