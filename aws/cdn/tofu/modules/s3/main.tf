locals {
  default_tags = merge(var.default_tags, {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/s3/"
  })
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(local.default_tags, { Name = var.bucket_name })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "error_page" {
  for_each = var.error_page_files

  bucket       = aws_s3_bucket.this.id
  key          = each.key
  source       = each.value
  source_hash  = filemd5(each.value)
  content_type = "text/html; charset=utf-8"
  tags         = local.default_tags
}
