terraform {
  required_version = ">= 1.12"

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
