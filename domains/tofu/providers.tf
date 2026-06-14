provider "aws" {
  profile = "ghilbut-platform"
  region  = "us-east-1"

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
