locals {
  default_tags = {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/github-actions/"
  }
}

resource "aws_iam_role" "this" {
  name = "${var.name}-github-actions"
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
  tags = merge(local.default_tags, { Name = "${var.name}-github-actions" })
}

data "aws_iam_policy_document" "apply" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket}"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["env:/", var.state_key, "${var.state_key}.tflock"]
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
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCors",
      "s3:GetBucketEncryption",
      "s3:GetBucketLifecycleConfiguration",
      "s3:GetBucketLogging",
      "s3:GetBucketPolicy",
      "s3:GetBucketReplication",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetObjectLockConfiguration",
      "s3:ListBucket",
      "s3:ListTagsForResource",
    ]
    resources = [var.cdn_bucket_arn]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${var.cdn_bucket_arn}/404.html",
      "${var.cdn_bucket_arn}/503.html",
      "${var.cdn_bucket_arn}/lambda.zip",
    ]
  }

  statement {
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetFunctionConfiguration",
      "lambda:ListTags",
      "lambda:ListVersionsByFunction",
      "lambda:PublishVersion",
      "lambda:UpdateFunctionCode",
    ]
    resources = [var.lambda_function_arn, "${var.lambda_function_arn}:*"]
  }

  statement {
    actions   = ["cloudfront:GetDistribution", "cloudfront:GetDistributionConfig", "cloudfront:ListTagsForResource", "cloudfront:UpdateDistribution"]
    resources = [var.cloudfront_distribution_arn]
  }

  statement {
    actions   = ["cloudfront:DescribeFunction", "cloudfront:GetFunction", "cloudfront:ListTagsForResource"]
    resources = [var.cloudfront_function_arn]
  }

  statement {
    actions   = ["cloudfront:GetOriginAccessControl"]
    resources = [var.origin_access_control_arn]
  }

  statement {
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
    ]
    resources = [var.lambda_role_arn]
  }

  statement {
    actions   = ["acm:DescribeCertificate", "acm:ListTagsForCertificate"]
    resources = [var.acm_certificate_arn]
  }

}

resource "aws_iam_role_policy" "apply" {
  name   = "deploy-cdn-artifacts"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.apply.json
}

resource "github_actions_variable" "cdn_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN"
  value         = aws_iam_role.this.arn
}
