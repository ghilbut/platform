provider "aws" {
  profile = "ghilbut"
  region  = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "accounts"
      component       = "aws"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "accounts/tofu/"
    }
  }
}
