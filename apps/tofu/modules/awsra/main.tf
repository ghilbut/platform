data "aws_caller_identity" "current" {}

locals {
  pkcs8_password = fileexists(var.pkcs8_password_file_path) ? sensitive(trimspace(file(var.pkcs8_password_file_path))) : null
}

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

resource "kubernetes_secret_v1" "awsra" {
  metadata {
    name      = "awsra"
    namespace = "vault"
  }

  data_wo = {
    AWS_ROLESANYWHERE_PKCS8_PASSWORD = local.pkcs8_password
  }

  data_wo_revision = var.pkcs8_password_revision

  type = "Opaque"

  lifecycle {
    precondition {
      condition     = local.pkcs8_password != null
      error_message = "The PKCS#8 passphrase file is required to apply the AWS Roles Anywhere Secret."
    }
  }
}

resource "local_file" "config_map_manifest" {
  filename = "${var.manifest_directory_path}/awsra-cm.yaml"

  content = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "awsra"
      namespace = "vault"
    }
    data = {
      AWS_ROLESANYWHERE_PROFILE_ARN      = aws_rolesanywhere_profile.awsra.arn
      AWS_ROLESANYWHERE_ROLE_ARN         = aws_iam_role.awsra.arn
      AWS_ROLESANYWHERE_TRUST_ANCHOR_ARN = aws_rolesanywhere_trust_anchor.awsra.arn
    }
  })
}
