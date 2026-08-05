terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket       = "ghilbut-tfstates"
    encrypt      = true
    key          = "k3s.tfstate"
    profile      = "ghilbut-tofu-apply-for-workloads"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

language {
  compatible_with {
    opentofu = ">= 1.12"
  }
}
