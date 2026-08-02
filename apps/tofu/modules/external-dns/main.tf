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
  managed_record_names = toset(flatten([
    for cluster in values(var.clusters) : concat(
      tolist(cluster.record_names),
      [for record_name in cluster.record_names : "${cluster.txt_prefix}${record_name}"],
    )
  ]))
}

resource "aws_iam_role" "external_dns" {
  name = "${var.name}-external-dns"

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

resource "aws_iam_role_policy" "route53" {
  name = "${var.name}-external-dns-route53"
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
        Action   = ["route53:ListHostedZonesByName"]
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
