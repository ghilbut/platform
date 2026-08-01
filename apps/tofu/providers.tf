provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "apps"
      component       = "aws-roles-anywhere"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "apps/tofu/"
    }
  }
}
