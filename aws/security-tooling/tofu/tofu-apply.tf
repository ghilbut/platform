resource "aws_iam_role" "tofu_apply" {
  name                 = "tofu-apply"
  description          = "OpenTofu execution role for the SecurityTooling account."
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
          "aws:PrincipalArn" = "arn:aws:iam::${local.security_tooling_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "tofu_apply" {
  name = "tofu-apply-inline"
  role = aws_iam_role.tofu_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageExecutionRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
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
