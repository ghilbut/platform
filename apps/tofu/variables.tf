variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for the Domains account that owns the Apps state."
  default     = "ghilbut-tofu-apply-for-workloads-domains"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for the Apps state."
  default     = "us-east-1"
}
