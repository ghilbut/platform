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
  managed_record_names = setunion(
    var.record_names,
    toset([for record_name in var.record_names : "${var.txt_prefix}${record_name}"]),
  )
}

resource "aws_iam_role" "external_dns" {
  name = "${var.name}-${var.cluster_name}-external-dns"

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

resource "aws_iam_role_policy" "route53" {
  name = "${var.name}-${var.cluster_name}-external-dns-route53"
  role = aws_iam_role.external_dns.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDnsChanges"
        Effect   = "Allow"
        Action   = ["route53:GetChange"]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Sid      = "DiscoverPublicHostedZones"
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListHostedZonesByName"]
        Resource = "*"
      },
      {
        Sid      = "ListManagedZoneRecords"
        Effect   = "Allow"
        Action   = ["route53:ListResourceRecordSets"]
        Resource = [for zone in data.aws_route53_zone.this : zone.arn]
      },
      {
        Sid      = "ManageDeclaredDnsRecords"
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = [for zone in data.aws_route53_zone.this : zone.arn]
        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsActions"               = ["CREATE", "UPSERT", "DELETE"]
            "route53:ChangeResourceRecordSetsNormalizedRecordNames" = tolist(local.managed_record_names)
            "route53:ChangeResourceRecordSetsRecordTypes"           = ["CNAME", "TXT"]
          }
        }
      },
    ]
  })
}
