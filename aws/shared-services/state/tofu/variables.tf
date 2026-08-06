variable "aws_execution_role_arn" {
  type        = string
  description = "SharedServices OpenTofu execution role assumed by the AWS provider."
  default     = "arn:aws:iam::012646747332:role/tofu-plan"

  validation {
    condition = contains([
      "arn:aws:iam::012646747332:role/tofu-plan",
      "arn:aws:iam::012646747332:role/tofu-state-admin",
    ], var.aws_execution_role_arn)
    error_message = "aws_execution_role_arn must be the SharedServices account tofu-plan or tofu-state-admin role ARN."
  }
}
