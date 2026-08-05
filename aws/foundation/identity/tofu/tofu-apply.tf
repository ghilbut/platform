resource "aws_iam_role" "tofu_apply" {
  name                 = "tofu-apply"
  description          = "OpenTofu execution role for Foundation management-account resources."
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
        AWS = "arn:aws:iam::384959722788:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::384959722788:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForManagement_*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "tofu_apply" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess",
    "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator",
    "arn:aws:iam::aws:policy/IAMFullAccess",
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
        Sid    = "AccountRegionManagement"
        Effect = "Allow"
        Action = [
          "account:DisableRegion",
          "account:EnableRegion",
          "account:GetRegionOptStatus",
          "account:ListRegions",
        ]
        Resource = "*"
      },
      {
        Sid      = "BootstrapDomainsExecutionRoles"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::869061964712:role/OrganizationAccountAccessRole"
      },
    ]
  })
}
