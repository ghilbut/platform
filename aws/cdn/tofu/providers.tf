################################################################
##  AWS provider
##
##  Lambda@Edge, ACM, and CloudFront require us-east-1.
################################################################

provider "aws" {
  allowed_account_ids = ["012646747332"]
  region              = "us-east-1"

  dynamic "assume_role" {
    for_each = var.aws_execution_role_arn == "" ? [] : [var.aws_execution_role_arn]

    content {
      role_arn = assume_role.value
    }
  }

  default_tags {
    tags = {
      created_by      = "opentofu"
      managed_by      = "opentofu"
      project         = var.project
      service         = var.service
      "opentofu/repo" = "https://github.com/ghilbut/platform"
      "opentofu/path" = "aws/cdn/tofu/"
    }
  }
}
