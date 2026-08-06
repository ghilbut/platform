resource "aws_iam_role" "tofu_plan" {
  name                 = "tofu-plan"
  description          = "Read-only OpenTofu execution role for Domains account resources."
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
          "aws:PrincipalArn" = "arn:aws:iam::869061964712:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_TofuPlanForDomains_*"
        }
      }
      }, {
      Sid       = "AllowDeployer"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::012646747332:root" }
      Action    = "sts:AssumeRole"
      Condition = {
        ArnEquals = {
          "aws:PrincipalArn" = "arn:aws:iam::012646747332:role/deployer"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "tofu_plan" {
  name = "tofu-plan-inline"
  role = aws_iam_role.tofu_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDnsResources"
        Effect   = "Allow"
        Action   = ["route53:Get*", "route53:List*", "route53:TestDNSAnswer"]
        Resource = "*"
      },
      {
        Sid    = "ReadRegisteredDomains"
        Effect = "Allow"
        Action = [
          "route53domains:Check*",
          "route53domains:Get*",
          "route53domains:List*",
          "route53domains:View*",
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadManagedRoles"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:ListRoleTags",
        ]
        Resource = [
          "arn:aws:iam::869061964712:role/domains-cpa-cert-manager",
          "arn:aws:iam::869061964712:role/domains-cpa-external-dns",
          "arn:aws:iam::869061964712:role/tofu-apply",
          "arn:aws:iam::869061964712:role/tofu-plan",
        ]
      },
      {
        Sid      = "ListOidcProviders"
        Effect   = "Allow"
        Action   = "iam:ListOpenIDConnectProviders"
        Resource = "*"
      },
      {
        Sid    = "ReadCpaOidcProvider"
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviderTags",
        ]
        Resource = "arn:aws:iam::869061964712:oidc-provider/oidc.k3s.ghilbut.com/cpa"
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
