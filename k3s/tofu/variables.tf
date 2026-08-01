variable "cdn_bucket" {
  type        = string
  description = "S3 bucket used as the CloudFront origin"
  default     = "ghilbut-cloudfront-cdn"
}
