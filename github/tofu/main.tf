resource "aws_iam_openid_connect_provider" "github_actions" {
  provider = aws.domains

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = { Name = "github-actions" }
}

resource "aws_iam_openid_connect_provider" "github_actions_platform" {
  provider = aws.platform

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = { Name = "github-actions" }
}
