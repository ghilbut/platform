provider "aws" {
  profile = "ghilbut-platform"
  region  = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "github"
      component       = "oidc"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "github/tofu/"
    }
  }
}
