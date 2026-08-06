variable "aws_execution_role_arn" {
  type        = string
  description = "Account-local OpenTofu execution role assumed by the AWS provider. Set null only while bootstrapping the execution roles."
  default     = "arn:aws:iam::012646747332:role/tofu-plan"
  nullable    = true

  validation {
    condition = var.aws_execution_role_arn == null || contains([
      "arn:aws:iam::012646747332:role/tofu-plan",
      "arn:aws:iam::012646747332:role/tofu-apply",
    ], var.aws_execution_role_arn)
    error_message = "aws_execution_role_arn must be null or the SharedServices account tofu-plan or tofu-apply role ARN."
  }
}

variable "cdn_bucket" {
  type        = string
  description = "S3 bucket used as the CloudFront origin"
  default     = "ghilbut-cdn-platform"
}

variable "kubeconfig_path" {
  type        = string
  description = "Kubeconfig file used to manage CPA resources."
  default     = "~/.kube/config"
}
