provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      org             = "ghilbut"
      project         = "platform"
      service         = "foundation"
      component       = "workload-access"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/foundation/workload/tofu/"
    }
  }
}
