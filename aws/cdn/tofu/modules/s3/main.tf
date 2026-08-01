variable "bucket_name" { type = string }

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = { Name = var.bucket_name }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "arn" { value = aws_s3_bucket.this.arn }
output "name" { value = aws_s3_bucket.this.id }
output "regional_domain_name" { value = aws_s3_bucket.this.bucket_regional_domain_name }
output "public_access_block" { value = aws_s3_bucket_public_access_block.this.id }
