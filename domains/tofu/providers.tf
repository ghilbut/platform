provider "aws" {
  allowed_account_ids = ["869061964712"]
  region              = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::869061964712:role/tofu-apply-domains"
  }

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "domains"
      component       = "ghilbut"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "domains/tofu/"
    }
  }
}

provider "aws" {
  alias               = "bootstrap"
  allowed_account_ids = ["869061964712"]
  region              = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "domains"
      component       = "ghilbut"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "domains/tofu/"
    }
  }
}
