provider "aws" {
  allowed_account_ids = ["869061964712"]
  profile             = var.aws_profile
  region              = var.aws_region

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "apps"
      component       = "aws-iam-federation"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "apps/tofu/"
    }
  }
}
