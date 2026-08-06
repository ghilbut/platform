resource "aws_iam_role" "tofu_state_admin" {
  name                 = "tofu-state-admin"
  description          = "OpenTofu execution role for state bucket administration."
  max_session_duration = 14400

  lifecycle {
    prevent_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIdentityCenterPermissionSet"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.shared_services_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${local.shared_services_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForWorkloads_*"
          }
        }
      },
      {
        Sid    = "AllowDeployer"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.shared_services_account_id}:root"
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

resource "aws_iam_role_policy" "tofu_state_admin" {
  name = "tofu-state-admin-inline"
  role = aws_iam_role.tofu_state_admin.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ManageStateBucketConfiguration"
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = local.state_bucket_arns
      },
      {
        Sid      = "DenyStateBucketDeletion"
        Effect   = "Deny"
        Action   = "s3:DeleteBucket"
        Resource = local.state_bucket_arns
      },
      {
        Sid    = "ManageOwnRole"
        Effect = "Allow"
        Action = [
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
        Resource = aws_iam_role.tofu_state_admin.arn
      },
    ]
  })
}
