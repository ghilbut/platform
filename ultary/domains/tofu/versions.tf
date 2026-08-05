terraform {
  required_version = ">= 1.12"

  ## https://www.terraform.io/docs/language/settings/backends/s3.html
  backend "s3" {
    bucket       = "ghilbut-tfstates"
    encrypt      = true
    key          = "ultary/domains.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    assume_role = {
      role_arn = "arn:aws:iam::012646747332:role/tofu-state-readonly"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
  }
}

language {
  compatible_with {
    opentofu = ">= 1.12"
  }
}
