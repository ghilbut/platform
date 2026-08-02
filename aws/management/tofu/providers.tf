provider "aws" {
  profile = "ghilbut"
  region  = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "management"
      component       = "aws"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/management/tofu/"
    }
  }
}

provider "aws" {
  alias   = "platform"
  profile = "ghilbut-platform"
  region  = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "management"
      component       = "aws"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/management/tofu/"
    }
  }
}

provider "aws" {
  alias   = "ultary"
  profile = "ultary-domains"
  region  = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "management"
      component       = "aws"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/management/tofu/"
    }
  }
}
