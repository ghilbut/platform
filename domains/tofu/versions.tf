terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket       = "ghilbut-tfstates"
    encrypt      = true
    key          = "platform/domains.tfstate"
    profile      = "ghilbut-platform"
    region       = "us-east-1"
    use_lockfile = true
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
