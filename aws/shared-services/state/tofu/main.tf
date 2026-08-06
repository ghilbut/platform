data "aws_caller_identity" "current" {}

locals {
  state_buckets = {
    primary = "ghilbut-tfstates"
  }
  shared_services_account_id = data.aws_caller_identity.current.account_id
  deployer_role_arn          = "arn:aws:iam::${local.shared_services_account_id}:role/deployer"
  state_bucket_arns          = [for bucket in values(local.state_buckets) : "arn:aws:s3:::${bucket}"]
}
