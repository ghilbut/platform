terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket       = "ghilbut-tfstates-v2"
    key          = "platform/apps.tfstate"
    profile      = "ghilbut-tofu-apply-for-workloads"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
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
