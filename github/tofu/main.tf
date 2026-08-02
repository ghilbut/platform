resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = { Name = "github-actions" }
}

data "terraform_remote_state" "cdn" {
  backend = "s3"

  config = {
    bucket  = "ghilbut-tfstates"
    encrypt = true
    key     = "platform/aws/cdn.tfstate"
    profile = "ghilbut-platform"
    region  = "us-east-1"
  }
}

resource "github_actions_variable" "cdn_role_arn" {
  repository    = "platform"
  variable_name = "AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN"
  value         = data.terraform_remote_state.cdn.outputs.github_actions_role_arn
}
