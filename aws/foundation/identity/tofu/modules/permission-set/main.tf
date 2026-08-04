resource "aws_ssoadmin_permission_set" "this" {
  instance_arn     = var.instance_arn
  name             = var.name
  description      = var.description
  session_duration = var.session_duration

  # 이름 변경은 새 permission set을 먼저 만들고 기존 permission set을 나중에 제거한다.
  # 같은 이름으로 강제 교체하면 AWS의 permission set 이름 중복 제한 때문에 실패한다.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = var.managed_policy_arns

  instance_arn       = var.instance_arn
  managed_policy_arn = each.value
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count = var.inline_policy == null ? 0 : 1

  inline_policy      = var.inline_policy
  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.account_assignments

  instance_arn       = var.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  principal_id       = each.value.principal_id
  principal_type     = each.value.principal_type
  target_id          = each.value.account_id
  target_type        = "AWS_ACCOUNT"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_ssoadmin_managed_policy_attachment.this,
    aws_ssoadmin_permission_set_inline_policy.this,
  ]
}
