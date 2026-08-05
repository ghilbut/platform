terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket       = "ghilbut-tfstates"
    key          = "platform/aws/shared-services.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    assume_role = {
      role_arn = "arn:aws:iam::012646747332:role/tofu-state-readonly"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.49"
    }
  }
}

language {
  compatible_with {
    opentofu = ">= 1.12"
  }
}
