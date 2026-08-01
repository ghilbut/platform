output "arn" { value = aws_s3_bucket.this.arn }
output "name" { value = aws_s3_bucket.this.id }
output "regional_domain_name" { value = aws_s3_bucket.this.bucket_regional_domain_name }
output "public_access_block" { value = aws_s3_bucket_public_access_block.this.id }
