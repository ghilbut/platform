variable "bucket_arn" { type = string }
variable "bucket_name" { type = string }
variable "name" { type = string }
variable "allowlist" { type = list(string) }
variable "redirect_map" { type = map(string) }
variable "spa_hosts" { type = list(string) }

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
  tags               = { Name = "${var.name}-cdn-lambda" }
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

data "aws_s3_object" "lambda_zip" {
  bucket = var.bucket_name
  key    = "lambda.zip"
}

data "aws_s3_object" "lambda_sha256" {
  bucket = var.bucket_name
  key    = "lambda.zip.sha256"
}

resource "aws_lambda_function" "this" {
  function_name = "${var.name}-cdn"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs24.x"
  publish       = true

  s3_bucket        = var.bucket_name
  s3_key           = data.aws_s3_object.lambda_zip.key
  source_code_hash = trimspace(data.aws_s3_object.lambda_sha256.body)
  tags             = { Name = "${var.name}-cdn" }
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
}

output "lambda_function_arn" { value = aws_lambda_function.this.qualified_arn }
output "lambda_role_arn" { value = aws_iam_role.lambda.arn }
output "viewer_request_function_arn" { value = aws_cloudfront_function.viewer_request.arn }
