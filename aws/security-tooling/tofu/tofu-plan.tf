resource "aws_iam_role" "tofu_plan" {
  name                 = "tofu-plan"
  description          = "Read-only OpenTofu execution role for the SecurityTooling account."
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
            "aws:PrincipalArn" = "arn:aws:iam::${local.security_tooling_account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForWorkloads_*"
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

resource "aws_iam_role_policy_attachment" "tofu_plan" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  role       = aws_iam_role.tofu_plan.name
}

resource "aws_iam_role_policy" "tofu_plan" {
  name = "tofu-plan-deny-state"
  role = aws_iam_role.tofu_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDirectStateObjectRead"
        Effect   = "Deny"
        Action   = "s3:GetObject*"
        Resource = local.protected_state_object_arns
      },
    ]
  })
}
