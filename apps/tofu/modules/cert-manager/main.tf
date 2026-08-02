data "aws_iam_openid_connect_provider" "this" {
  for_each = var.clusters

  url = each.value.oidc_issuer
}

data "aws_route53_zone" "this" {
  for_each     = local.hosted_zone_names
  name         = each.value
  private_zone = false
}

locals {
  hosted_zone_names = toset(flatten([
    for cluster in values(var.clusters) : tolist(cluster.hosted_zone_names)
  ]))
}

resource "aws_iam_role" "cert_manager" {
  name = "${var.name}-cert-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [for cluster_name, cluster in var.clusters : {
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = data.aws_iam_openid_connect_provider.this[cluster_name].arn }
      Condition = {
        StringEquals = {
          "${trimprefix(cluster.oidc_issuer, "https://")}:aud" = "sts.amazonaws.com"
          "${trimprefix(cluster.oidc_issuer, "https://")}:sub" = "system:serviceaccount:${cluster.service_account_namespace}:${cluster.service_account_name}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "route53_dns01" {
  name = "${var.name}-cert-manager-route53-dns01"
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
