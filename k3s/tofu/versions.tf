terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket       = "ghilbut-tfstates"
    encrypt      = true
    key          = "k3s.tfstate"
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
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

language {
  compatible_with {
    opentofu = ">= 1.12"
  }
}
