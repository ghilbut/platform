provider "aws" {
  allowed_account_ids = ["012646747332"]
  region              = "us-east-1"

  assume_role {
    role_arn = var.aws_execution_role_arn
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
      "opentofu/path" = "aws/shared-services/state/tofu/"
    }
  }
}
