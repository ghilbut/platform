################################################################
##  AWS provider
##
##  Lambda@Edge, ACM, and CloudFront require us-east-1.
################################################################

provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::869061964712:role/tofu-apply"
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

provider "github" {
  owner = var.github_owner
}
