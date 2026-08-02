data "aws_iam_openid_connect_provider" "this" {
  url = var.oidc_issuer
}

data "aws_route53_zone" "this" {
  for_each     = var.hosted_zone_names
  name         = each.value
  private_zone = false
}

locals {
  oidc_condition_prefix = trimprefix(var.oidc_issuer, "https://")
}

resource "aws_iam_role" "cert_manager" {
  name = "${var.name}-${var.cluster_name}-cert-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = data.aws_iam_openid_connect_provider.this.arn }
        Condition = {
          StringEquals = {
            "${local.oidc_condition_prefix}:aud" = "sts.amazonaws.com"
            "${local.oidc_condition_prefix}:sub" = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "route53_dns01" {
  name = "${var.name}-${var.cluster_name}-cert-manager-route53-dns01"
  role = aws_iam_role.cert_manager.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDnsChallengeChanges"
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Sid      = "DiscoverDnsChallengeZones"
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = "*"
      },
      {
        Sid      = "ListDnsChallengeRecords"
        Effect   = "Allow"
        Action   = ["route53:ListResourceRecordSets"]
        Resource = [for zone in data.aws_route53_zone.this : zone.arn]
      },
      {
        Sid      = "ManageDnsChallengeRecords"
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = [for zone in data.aws_route53_zone.this : zone.arn]
        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsRecordTypes" = ["TXT"]
          }
        }
      },
    ]
  })
}
