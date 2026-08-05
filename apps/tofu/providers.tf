provider "aws" {
  allowed_account_ids = ["012646747332"]
  region              = var.aws_region

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
      service         = "apps"
      component       = "aws-iam-federation"
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "apps/tofu/"
    }
  }
}
