data "aws_caller_identity" "current" {}

resource "aws_rolesanywhere_trust_anchor" "awsra" {
  name    = "${var.name}-awsra"
  enabled = true

  source {
    source_type = "CERTIFICATE_BUNDLE"
    source_data {
      x509_certificate_data = file(var.trust_anchor_certificate_path)
    }
  }
}

resource "aws_iam_role" "awsra" {
  name = "${var.name}-awsra"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:SetSourceIdentity",
          "sts:TagSession",
        ]
        Principal = {
          Service = "rolesanywhere.amazonaws.com"
        }
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_rolesanywhere_trust_anchor.awsra.arn
          }
          StringEquals = {
            "aws:SourceAccount"  = data.aws_caller_identity.current.account_id
            "sts:SourceIdentity" = var.certificate_subject_common_name
          }
        }
      },
    ]
  })
}

resource "aws_rolesanywhere_profile" "awsra" {
  name                        = "${var.name}-awsra"
  enabled                     = true
  role_arns                   = [aws_iam_role.awsra.arn]
  duration_seconds            = var.session_duration_seconds
  accept_role_session_name    = false
  require_instance_properties = false
}
