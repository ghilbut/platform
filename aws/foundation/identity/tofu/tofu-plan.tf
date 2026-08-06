resource "aws_iam_role" "tofu_plan" {
  name                 = "tofu-plan"
  description          = "OpenTofu plan role for Foundation management-account resources."
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
          AWS = "arn:aws:iam::384959722788:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:PrincipalArn" = "arn:aws:iam::384959722788:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForManagement_*"
          }
        }
      },
      {
        Sid       = "AllowDeployer"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::012646747332:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = "arn:aws:iam::012646747332:role/deployer"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "tofu_plan" {
  name = "tofu-plan-read"
  role = aws_iam_role.tofu_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccountRead"
        Effect = "Allow"
        Action = [
          "account:GetRegionOptStatus",
          "account:ListRegions",
        ]
        Resource = "*"
      },
      {
        Sid    = "OrganizationsRead"
        Effect = "Allow"
        Action = [
          "organizations:Describe*",
          "organizations:List*",
        ]
        Resource = "*"
      },
      {
        Sid    = "IdentityCenterRead"
        Effect = "Allow"
        Action = [
          "sso:DescribePermissionSet",
          "sso:GetInlinePolicyForPermissionSet",
          "sso:ListAccountAssignments",
          "sso:ListInstances",
          "sso:ListManagedPoliciesInPermissionSet",
          "sso:ListTagsForResource",
        ]
        Resource = "*"
      },
      {
        Sid    = "IdentityStoreRead"
        Effect = "Allow"
        Action = [
          "identitystore:DescribeGroup",
          "identitystore:DescribeGroupMembership",
        ]
        Resource = "*"
      },
      {
        Sid    = "IamRoleRead"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]
        Resource = "arn:aws:iam::384959722788:role/*"
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
