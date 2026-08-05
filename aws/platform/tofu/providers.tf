provider "aws" {
  allowed_account_ids = ["012646747332"]
  region              = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "platform"
      component       = "workload-access"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/platform/tofu/"
    }
  }
}

provider "aws" {
  alias               = "platform"
  allowed_account_ids = ["012646747332"]
  region              = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::012646747332:role/tofu-apply"
  }

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "platform"
      component       = "state"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/platform/tofu/"
    }
  }
}
