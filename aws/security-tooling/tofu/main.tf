data "aws_caller_identity" "current" {}

locals {
  security_tooling_account_id = data.aws_caller_identity.current.account_id
  execution_role_arns = [
    "arn:aws:iam::${local.security_tooling_account_id}:role/tofu-apply",
    "arn:aws:iam::${local.security_tooling_account_id}:role/tofu-plan",
  ]
}
