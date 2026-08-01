locals {
  # Flatten zones -> hosts into a map of FQDN -> host config
  fqdn_hosts = merge([
    for zone, hosts in var.zones : {
      for host, cfg in hosts :
      "${host}.${zone}" => cfg
    }
  ]...)

  # All FQDNs served (used for ACM SAN and Route53 records)
  fqdns = keys(local.fqdn_hosts)

  # Data baked into viewer-request CloudFront Function at tofu apply time.
  # Single source of truth: var.zones. config.json is no longer used.
  viewer_request_allowlist = keys(local.fqdn_hosts)
  viewer_request_redirect_map = {
    for fqdn, cfg in local.fqdn_hosts : fqdn => cfg.redirect_host
    if cfg.mode == "redirect"
  }
  viewer_request_spa_hosts = [
    for fqdn, cfg in local.fqdn_hosts : fqdn
    if cfg.mode == "spa"
  ]

  default_tags = merge(var.default_tags, {
    "opentofu/module/repo" = "https://github.com/ghilbut/platform"
    "opentofu/module/path" = "aws/cdn/tofu/"
  })

  github_issuer         = "https://token.actions.githubusercontent.com"
  opentofu_state_bucket = "ghilbut-tfstates"
  opentofu_state_key    = "aws/cdn.tfstate"
}



################################################################
##  S3
################################################################

resource "aws_s3_bucket" "this" {
  bucket = "ghilbut-cloudfront-cdn"

  tags = merge(local.default_tags, {
    Name = "ghilbut-cloudfront-cdn"
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


################################################################
##  IAM — Lambda@Edge execution role
################################################################

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-cdn-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = merge(local.default_tags, {
    Name = "${var.name}-cdn-lambda"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_role_policy" "lambda_s3" {
  name   = "${var.name}-cdn-lambda-s3"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_s3.json
}


################################################################
##  Lambda@Edge
################################################################

data "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.this.id
  key    = "lambda.zip"
}

# SHA-256 (base64) of lambda.zip, uploaded alongside the zip by CI.
# Used as source_code_hash so tofu detects Lambda code changes without S3 versioning.
data "aws_s3_object" "lambda_sha256" {
  bucket = aws_s3_bucket.this.id
  key    = "lambda.zip.sha256"
}

resource "aws_lambda_function" "this" {
  function_name = "${var.name}-cdn"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs24.x"
  publish       = true

  s3_bucket        = aws_s3_bucket.this.id
  s3_key           = data.aws_s3_object.lambda_zip.key
  source_code_hash = trimspace(data.aws_s3_object.lambda_sha256.body)

  tags = merge(local.default_tags, {
    Name = "${var.name}-cdn"
  })
}


################################################################
##  Route53 zone lookup
################################################################

data "aws_route53_zone" "zones" {
  for_each = var.zones

  name         = each.key
  private_zone = false
}

# ACM anchor domain zone — looked up independently so that acm_domain_name
# does not need to be a key in var.zones.
data "aws_route53_zone" "acm_domain" {
  name         = var.acm_domain_name
  private_zone = false
}

locals {
  # Merge host zones with the ACM anchor domain zone so that certificate
  # validation records can be created for all DVOs including the anchor domain.
  # acm_domain_name may overlap with a var.zones key (common case) or not.
  zone_id_by_root = merge(
    { for zone, z in data.aws_route53_zone.zones : zone => z.zone_id },
    { (var.acm_domain_name) = data.aws_route53_zone.acm_domain.zone_id },
  )
}


################################################################
##  ACM
################################################################

resource "aws_acm_certificate" "this" {
  domain_name               = var.acm_domain_name
  subject_alternative_names = local.fqdns
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags, {
    Name = "${var.name}-cdn-certificate"
  })
}

resource "aws_route53_record" "certificate" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      # Resolve zone_id from zone_id_by_root which includes both host zones
      # and the ACM anchor domain zone, so acm_domain_name does not need to
      # be a key in var.zones.
      zone_id = local.zone_id_by_root[
        one([
          for zone in keys(local.zone_id_by_root) : zone
          if dvo.domain_name == zone || endswith(dvo.domain_name, ".${zone}")
        ])
      ]
    }
  }

  allow_overwrite = true

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = each.value.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.certificate : r.fqdn]
}


################################################################
##  CloudFront OAC
################################################################

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.name}-cdn-oac"
  description                       = "OAC for ${var.name} CDN S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "viewer_request" {
  name    = "${var.name}-cdn-viewer-request"
  runtime = "cloudfront-js-2.0"
  publish = true
  comment = "Host validation, redirect, SPA header, and URI prefix"
  code = templatefile("${path.module}/viewer-request.js.tftpl", {
    allowlist    = local.viewer_request_allowlist
    redirect_map = local.viewer_request_redirect_map
    spa_hosts    = local.viewer_request_spa_hosts
  })
}


################################################################
##  CloudFront Distribution
################################################################

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  aliases             = local.fqdns
  comment             = "${var.name} CDN"
  wait_for_deployment = false

  origin {
    origin_id                = "s3-cdn"
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-cdn"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = []
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.this.qualified_arn
      include_body = false
    }
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 503
    response_code         = 503
    response_page_path    = "/503.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.this.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(local.default_tags, {
    Name = "${var.name}-cdn"
  })

  depends_on = [aws_acm_certificate_validation.this]
}


################################################################
##  S3 Bucket Policy — allow CloudFront OAC
################################################################

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}


################################################################
##  GitHub Actions — OIDC + IAM role
################################################################

data "aws_iam_openid_connect_provider" "github" {
  url = local.github_issuer
}

resource "aws_iam_role" "github" {
  name = "ghilbut-platform-github-actions-cdn"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:ghilbut/platform:*"
          }
        }
      }
    ]
  })

  tags = merge(local.default_tags, {
    Name = "ghilbut-platform-github-actions-cdn"
  })
}

data "aws_iam_policy_document" "github_upload" {
  statement {
    actions = ["s3:PutObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.this.arn}/404.html",
      "${aws_s3_bucket.this.arn}/503.html",
      "${aws_s3_bucket.this.arn}/lambda.zip",
      "${aws_s3_bucket.this.arn}/lambda.zip.sha256",
    ]
  }
}

resource "aws_iam_role_policy" "github_upload" {
  name   = "upload-s3-objects"
  role   = aws_iam_role.github.name
  policy = data.aws_iam_policy_document.github_upload.json
}

data "aws_iam_policy_document" "github_apply" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${local.opentofu_state_bucket}",
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        local.opentofu_state_key,
        "${local.opentofu_state_key}.tflock",
      ]
    }
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.opentofu_state_bucket}/${local.opentofu_state_key}",
      "arn:aws:s3:::${local.opentofu_state_bucket}/${local.opentofu_state_key}.tflock",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:Get*",
    ]
    resources = [
      aws_s3_bucket.this.arn,
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/lambda.zip",
      "${aws_s3_bucket.this.arn}/lambda.zip.sha256",
    ]
  }

  statement {
    actions = [
      "s3:GetAccelerateConfiguration",
    ]
    resources = [
      aws_s3_bucket.this.arn,
    ]
  }

  statement {
    actions = [
      "lambda:DisableReplication*",
      "lambda:EnableReplication*",
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetFunctionConfiguration",
      "lambda:ListVersionsByFunction",
      "lambda:ListTags",
      "lambda:PublishVersion",
      "lambda:UpdateFunctionCode",
    ]
    resources = [
      aws_lambda_function.this.arn,
      "${aws_lambda_function.this.arn}:*",
    ]
  }

  statement {
    actions = [
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListTagsForResource",
      "cloudfront:UpdateDistribution",
    ]
    resources = [
      aws_cloudfront_distribution.this.arn,
    ]
  }

  statement {
    actions = [
      "cloudfront:GetOriginAccessControl",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "cloudfront:CreateFunction",
      "cloudfront:DescribeFunction",
      "cloudfront:GetFunction",
      "cloudfront:ListFunctions",
      "cloudfront:PublishFunction",
      "cloudfront:UpdateFunction",
      "cloudfront:UpdateFunctionCode",
      "cloudfront:UpdateFunctionMetadata",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
    ]
    resources = [
      aws_iam_role.lambda.arn,
    ]
  }

  statement {
    actions = [
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
    ]
    resources = [
      aws_acm_certificate.this.arn,
    ]
  }

  statement {
    actions = [
      "route53:GetHostedZone",
      "route53:ListHostedZones",
    ]
    resources = concat(
      ["*"],
      [
        for zone_id in distinct(values(local.zone_id_by_root)) :
        "arn:aws:route53:::hostedzone/${zone_id}"
      ],
    )
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetChange",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = [
      for zone_id in distinct(values(local.zone_id_by_root)) :
      "arn:aws:route53:::hostedzone/${zone_id}"
    ]
  }
}

resource "aws_iam_role_policy" "github_apply" {
  name   = "apply-lambda-function"
  role   = aws_iam_role.github.name
  policy = data.aws_iam_policy_document.github_apply.json
}

resource "github_actions_variable" "cdn_role_arn" {
  repository    = var.github_repository
  variable_name = "AWS_IAM_ROLE_CDN_GITHUB_ACTIONS_ARN"
  value         = aws_iam_role.github.arn
}


################################################################
##  Route53 — FQDN A records -> CloudFront
################################################################

resource "aws_route53_record" "this" {
  for_each = {
    for fqdn in local.fqdns : fqdn => local.zone_id_by_root[
      one([
        for zone in keys(var.zones) : zone
        if fqdn == zone || endswith(fqdn, ".${zone}")
      ])
    ]
  }

  name    = each.key
  type    = "A"
  zone_id = each.value

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
  }
}
