locals {
  github_state_key = "platform/github.tfstate"
}

data "terraform_remote_state" "github" {
  backend = "s3"

  config = {
    bucket  = "ghilbut-tfstates-v2"
    encrypt = true
    key     = local.github_state_key
    region  = "us-east-1"
  }
}
