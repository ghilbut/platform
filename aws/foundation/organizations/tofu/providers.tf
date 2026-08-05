provider "aws" {
  region = "us-east-1"

  dynamic "assume_role" {
    for_each = var.aws_execution_role_arn == null ? [] : [var.aws_execution_role_arn]

    content {
      role_arn = assume_role.value
    }
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
