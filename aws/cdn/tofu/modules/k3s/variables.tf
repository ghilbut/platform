variable "cdn_bucket" {
  type        = string
  description = "S3 bucket used as the CloudFront origin"
}

variable "kubectl_context" {
  type        = string
  description = "kubectl context for the K3S cluster"
}

variable "s3_prefix" {
  type        = string
  description = "S3 key prefix and public OIDC issuer path"
}
