provider "aws" {
  allowed_account_ids = ["012646747332"]
  region              = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "shared-services"
      component       = "workload-access"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/shared-services/tofu/"
    }
  }
}

provider "aws" {
  alias               = "shared_services"
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
      service         = "shared-services"
      component       = "state"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/shared-services/tofu/"
    }
  }
}
