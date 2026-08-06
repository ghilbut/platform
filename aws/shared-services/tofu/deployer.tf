resource "aws_iam_role" "deployer" {
  name                 = "deployer"
  description          = "CI/CD source role for OpenTofu and workload deployment."
  max_session_duration = 3600

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowGitHubActions"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:ghilbut/platform:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deployer" {
  name = "assume-opentofu-roles"
  role = aws_iam_role.deployer.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AssumeOpenTofuRoles"
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Resource = [
        "arn:aws:iam::384959722788:role/tofu-apply",
        "arn:aws:iam::384959722788:role/tofu-plan",
        "arn:aws:iam::869061964712:role/tofu-apply",
        "arn:aws:iam::869061964712:role/tofu-plan",
        "arn:aws:iam::954066442429:role/tofu-apply",
        "arn:aws:iam::954066442429:role/tofu-plan",
        aws_iam_role.tofu_apply.arn,
        aws_iam_role.tofu_plan.arn,
        aws_iam_role.tofu_state_apply.arn,
        aws_iam_role.tofu_state_readonly.arn,
      ]
    }]
  })
}
