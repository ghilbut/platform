resource "aws_organizations_account" "management" {
  name  = "Management"
  email = "aws@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "domains" {
  name  = "Domains"
  email = "aws-domains@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "shared_services" {
  name  = "SharedServices"
  email = "aws-platform@ghilbut.com"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "ultary" {
  name  = "UltaryDomains"
  email = "aws-ultary-domains@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}
