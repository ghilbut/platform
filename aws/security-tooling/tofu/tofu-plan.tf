resource "aws_iam_role" "tofu_plan" {
  name                 = "tofu-plan"
  description          = "Read-only OpenTofu execution role for the SecurityTooling account."
  max_session_duration = 14400

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowIdentityCenterPermissionSet"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${local.security_tooling_account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${local.security_tooling_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForWorkloads_*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "tofu_plan" {
  name = "tofu-plan-read-only"
  role = aws_iam_role.tofu_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadExecutionRoles"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]
        Resource = local.execution_role_arns
      },
      {
        Sid      = "ReadCallerIdentity"
        Effect   = "Allow"
        Action   = "sts:GetCallerIdentity"
        Resource = "*"
      },
    ]
  })
}
