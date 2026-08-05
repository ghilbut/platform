provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::384959722788:role/tofu-apply"
  }

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "foundation"
      component       = "organizations"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/foundation/organizations/tofu/"
    }
  }
}
