terraform {
  required_version = ">= 1.12"

  ## https://www.terraform.io/docs/language/settings/backends/s3.html
  backend "s3" {
    bucket       = "ghilbut-tfstates-v2"
    encrypt      = true
    key          = "platform/aws/cdn.tfstate"
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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

language {
  compatible_with {
    opentofu = ">= 1.12"
  }
}
