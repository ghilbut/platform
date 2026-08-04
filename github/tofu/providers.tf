provider "aws" {
  alias               = "domains"
  allowed_account_ids = ["869061964712"]
  profile             = "ghilbut-tofu-apply-for-workloads-domains"
  region              = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::869061964712:role/tofu-apply"
  }

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      project         = "platform"
      service         = "github"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "github/tofu/"
    }
  }
}

provider "aws" {
  alias               = "platform"
  allowed_account_ids = ["012646747332"]
  profile             = "ghilbut-tofu-apply-for-workloads"
  region              = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::012646747332:role/tofu-apply"
  }

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      project         = "platform"
      service         = "github"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "github/tofu/"
    }
  }
}
