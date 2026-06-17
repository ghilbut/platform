################################################################
##  AWS Provider(s)
################################################################

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = {
      created_by   = "tofu"
      managed_by   = "tofu"
      organization = "ultary"
      owner        = "ultary@ultary.co"
      project      = "."
      service      = "domains"
      "tofu/repo"  = "https://github.com/ultaryinc/ultary"
      "tofu/path"  = "domains/tofu/"
    }
  }
}
