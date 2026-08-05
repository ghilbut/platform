resource "aws_iam_role" "tofu_apply" {
  name                 = "tofu-apply"
  description          = "OpenTofu execution role for Domains account Route 53 resources."
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
        AWS = "arn:aws:iam::869061964712:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::869061964712:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuApplyForDomains_*"
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
        Sid      = "Route53Management"
        Effect   = "Allow"
        Action   = ["route53:*", "route53domains:*"]
        Resource = "*"
      },
      {
        Sid    = "ReadExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
        ]
        Resource = "arn:aws:iam::869061964712:role/tofu-apply"
      },
      {
        Sid    = "ManageDnsFederationRoles"
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
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
        ]
        Resource = [
          "arn:aws:iam::869061964712:role/domains-cpa-cert-manager",
          "arn:aws:iam::869061964712:role/domains-cpa-external-dns",
        ]
      },
      {
        Sid    = "ManagePlanExecutionRole"
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
          "iam:PutRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
        ]
        Resource = "arn:aws:iam::869061964712:role/tofu-plan"
      },
      {
        Sid      = "CreateCpaOidcProvider"
        Effect   = "Allow"
        Action   = ["iam:ListOpenIDConnectProviders"]
        Resource = "*"
      },
      {
        Sid    = "ManageCpaOidcProvider"
        Effect = "Allow"
        Action = [
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
        ]
        Resource = "arn:aws:iam::869061964712:oidc-provider/oidc.k3s.ghilbut.com/cpa"
      },
    ]
  })
}
