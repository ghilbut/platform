resource "aws_iam_role" "billing" {
  name                 = "billing"
  description          = "Billing and cost management role for the Management account."
  max_session_duration = 14400

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowIdentityCenterPermissionSet"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::384959722788:root"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::384959722788:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_Billing_*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "billing" {
  role       = aws_iam_role.billing.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}
