moved {
  from = module.management_tofu_execution_role.aws_iam_role.this
  to   = aws_iam_role.tofu_apply
}

moved {
  from = module.management_tofu_execution_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"]
  to   = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"]
}

moved {
  from = module.management_tofu_execution_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator"]
  to   = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator"]
}

moved {
  from = module.management_tofu_execution_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/IAMFullAccess"]
  to   = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/IAMFullAccess"]
}

moved {
  from = module.management_tofu_execution_role.aws_iam_role_policy.this[0]
  to   = aws_iam_role_policy.tofu_apply
}

moved {
  from = module.tofu_apply_for_workloads.aws_ssoadmin_account_assignment.this["platform"]
  to   = module.tofu_apply_for_workloads.aws_ssoadmin_account_assignment.this["shared_services"]
}
