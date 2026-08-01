variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for the account that owns platform application resources."
  default     = "ghilbut-platform"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for platform application resources."
  default     = "us-east-1"
}
