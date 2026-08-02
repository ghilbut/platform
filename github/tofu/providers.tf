provider "aws" {
  profile = "ghilbut-platform"
  region  = "us-east-1"

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

provider "github" {
  owner = "ghilbut"
}
