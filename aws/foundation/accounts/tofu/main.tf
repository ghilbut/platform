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

moved {
  from = aws_organizations_account.platform
  to   = aws_organizations_account.domains
}

resource "aws_organizations_account" "domains" {
  name  = "domains"
  email = "aws-domains@ghilbut.com"

  tags = {
    created_by = "manual"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "new_platform" {
  name  = "platform"
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
