locals {
  default_tags = merge(var.default_tags, {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/github-actions/"
  })
}

resource "aws_iam_role" "this" {
  name = "ghilbut-platform-github-actions-cdn"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = var.github_actions_oidc_provider_arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.repository_full_name}:ref:refs/heads/main"
        }
      }
    }]
  })
  tags = merge(local.default_tags, { Name = "ghilbut-platform-github-actions-cdn" })
}

data "aws_iam_policy_document" "upload" {
  statement {
    actions = ["s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${var.cdn_bucket_arn}/404.html",
      "${var.cdn_bucket_arn}/503.html",
      "${var.cdn_bucket_arn}/lambda.zip",
    ]
  }
}

resource "aws_iam_role_policy" "upload" {
  name   = "upload-s3-objects"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.upload.json
}

data "aws_iam_policy_document" "apply" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.state_key, "${var.state_key}.tflock"]
    }
  }

  statement {
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.state_bucket}/${var.state_key}",
      "arn:aws:s3:::${var.state_bucket}/${var.state_key}.tflock",
    ]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.state_bucket}/${var.github_state_key}"]
  }

  statement {
    actions   = ["s3:ListBucket", "s3:Get*"]
    resources = [var.cdn_bucket_arn]
  }

  statement {
    actions = ["s3:GetObject", "s3:GetObjectTagging"]
    resources = [
      "${var.cdn_bucket_arn}/404.html",
      "${var.cdn_bucket_arn}/503.html",
      "${var.cdn_bucket_arn}/lambda.zip",
    ]
  }

  statement {
    actions   = ["s3:GetAccelerateConfiguration"]
    resources = [var.cdn_bucket_arn]
  }

  statement {
    actions = [
      "lambda:DisableReplication*", "lambda:EnableReplication*", "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig", "lambda:GetFunctionConfiguration",
      "lambda:ListVersionsByFunction", "lambda:ListTags", "lambda:PublishVersion",
      "lambda:UpdateFunctionCode",
    ]
    resources = [var.lambda_function_arn, "${var.lambda_function_arn}:*"]
  }

  statement {
    actions   = ["cloudfront:GetDistribution", "cloudfront:GetDistributionConfig", "cloudfront:ListTagsForResource", "cloudfront:UpdateDistribution"]
    resources = [var.cloudfront_distribution_arn]
  }

  statement {
    actions   = ["cloudfront:GetOriginAccessControl"]
    resources = ["*"]
  }

  statement {
    actions = [
      "cloudfront:CreateFunction", "cloudfront:DescribeFunction", "cloudfront:GetFunction",
      "cloudfront:ListFunctions", "cloudfront:PublishFunction", "cloudfront:UpdateFunction",
      "cloudfront:UpdateFunctionCode", "cloudfront:UpdateFunctionMetadata",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
    ]
    resources = [aws_iam_role.this.arn, var.lambda_role_arn]
  }

  statement {
    actions   = ["iam:GetOpenIDConnectProvider"]
    resources = [var.github_actions_oidc_provider_arn]
  }

  statement {
    actions   = ["acm:DescribeCertificate", "acm:ListTagsForCertificate"]
    resources = [var.acm_certificate_arn]
  }

  statement {
    actions   = ["route53:GetHostedZone", "route53:ListHostedZones"]
    resources = concat(["*"], [for zone_id in distinct(values(var.zone_ids)) : "arn:aws:route53:::hostedzone/${zone_id}"])
  }

  statement {
    actions   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
    resources = [for zone_id in distinct(values(var.zone_ids)) : "arn:aws:route53:::hostedzone/${zone_id}"]
  }

  statement {
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }
}

resource "aws_iam_role_policy" "apply" {
  name   = "apply-lambda-function"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.apply.json
}

resource "github_actions_variable" "cdn_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN"
  value         = aws_iam_role.this.arn
}
