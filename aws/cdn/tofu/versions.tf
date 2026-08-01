terraform {
  required_version = ">= 1.12"

  ## https://www.terraform.io/docs/language/settings/backends/s3.html
  backend "s3" {
    bucket       = "ghilbut-tfstates"
    encrypt      = true
    key          = "aws/cdn.tfstate"
    profile      = "ghilbut-platform"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

language {
  compatible_with {
    opentofu = ">= 1.12"
  }
}
