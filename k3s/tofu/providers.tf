provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "k3s"
      component       = "oidc"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "k3s/tofu/"
    }
  }
}
