################################################################
##  AWS provider
##
##  Lambda@Edge, ACM, and CloudFront require us-east-1.
################################################################

provider "aws" {
  profile = "ghilbut-platform"
  region  = "us-east-1"

  default_tags {
    tags = local.default_tags
  }
}

################################################################
##  GitHub provider
##
##  Used to manage repository Actions variables for CDN workflows.
################################################################

provider "github" {
  owner = var.github_owner
  app_auth {}
}
