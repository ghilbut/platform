moved {
  from = module.tofu_execution_role.aws_iam_role.this
  to   = aws_iam_role.tofu_apply
}

moved {
  from = module.tofu_execution_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/IAMFullAccess"]
  to   = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/IAMFullAccess"]
}

moved {
  from = module.tofu_execution_role.aws_iam_role_policy_attachment.this["arn:aws:iam::aws:policy/PowerUserAccess"]
  to   = aws_iam_role_policy_attachment.tofu_apply["arn:aws:iam::aws:policy/PowerUserAccess"]
}

moved {
  from = module.tofu_execution_role.aws_iam_role_policy.this[0]
  to   = aws_iam_role_policy.tofu_apply
}
