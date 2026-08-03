resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  max_session_duration = var.max_session_duration
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowIdentityCenterPermissionSet"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.source_account_id}:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${var.source_account_id}:role/aws-reserved/sso.amazonaws.com/${var.sso_region}/AWSReservedSSO_${var.source_permission_set_name}_*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.managed_policy_arns

  policy_arn = each.value
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy" "this" {
  count = var.inline_policy == null ? 0 : 1

  name   = "${var.name}-inline"
  policy = var.inline_policy
  role   = aws_iam_role.this.name
}
