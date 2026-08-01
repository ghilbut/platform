locals {
  default_tags = merge(var.default_tags, {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/edge/"
  })
}

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
  tags               = merge(local.default_tags, { Name = "${var.name}-cdn-lambda" })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "lambda_s3" {
  name   = "${var.name}-cdn-lambda-s3"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_s3.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.lambda_source_file
  output_path = "${path.root}/.terraform/${var.name}-cdn-lambda.zip"
}

resource "aws_s3_object" "lambda_zip" {
  bucket      = var.bucket_name
  key         = "lambda.zip"
  source      = data.archive_file.lambda.output_path
  source_hash = data.archive_file.lambda.output_base64sha256
  tags        = local.default_tags
}

resource "aws_lambda_function" "this" {
  function_name = "${var.name}-cdn"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs24.x"
  publish       = true

  s3_bucket        = var.bucket_name
  s3_key           = aws_s3_object.lambda_zip.key
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags             = merge(local.default_tags, { Name = "${var.name}-cdn" })
}

resource "aws_cloudfront_function" "viewer_request" {
  name    = "${var.name}-cdn-viewer-request"
  runtime = "cloudfront-js-2.0"
  publish = true
  comment = "Host validation, redirect, SPA header, and URI prefix"
  code = templatefile("${path.module}/viewer-request.js.tftpl", {
    allowlist    = var.allowlist
    redirect_map = var.redirect_map
    spa_hosts    = var.spa_hosts
  })
  tags = local.default_tags
}
