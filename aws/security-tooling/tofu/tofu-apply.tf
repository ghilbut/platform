resource "aws_iam_role" "tofu_apply" {
  name                 = "tofu-apply"
  description          = "OpenTofu execution role for the SecurityTooling account."
  max_session_duration = 14400

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
      },
      {
        Sid    = "AllowDeployer"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::012646747332:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = local.deployer_role_arn
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tofu_apply" {
  for_each = toset([
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/PowerUserAccess",
  ])

  policy_arn = each.value
  role       = aws_iam_role.tofu_apply.name
}

resource "aws_iam_role_policy" "tofu_apply" {
  name = "tofu-apply-inline"
  role = aws_iam_role.tofu_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyCentralAdministration"
        Effect   = "Deny"
        Action   = local.central_administration_denied_actions
        Resource = "*"
      },
      {
        Sid      = "DenyDirectStateAccess"
        Effect   = "Deny"
        Action   = "s3:*"
        Resource = concat(local.protected_state_bucket_arns, local.protected_state_object_arns)
      },
      {
        Sid    = "DenyStateAdministrationRoleChanges"
        Effect = "Deny"
        Action = [
          "iam:AttachRolePolicy",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:DeleteRolePermissionsBoundary",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:PutRolePermissionsBoundary",
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
          "sts:AssumeRole",
        ]
        Resource = local.state_admin_role_arn
      },
    ]
  })
}
