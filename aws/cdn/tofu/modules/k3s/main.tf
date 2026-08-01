data "external" "oidc_jwks" {
  program = [
    "bash",
    "-c",
    "set -euo pipefail; kubectl --context=\"$1\" get --raw /openid/v1/jwks | jq -c '{result: tojson}'",
    "bash",
    var.kubectl_context,
  ]
}

data "external" "openid_configuration" {
  program = [
    "bash",
    "-c",
    "set -euo pipefail; kubectl --context=\"$1\" get --raw /.well-known/openid-configuration | jq -c '{result: tojson}'",
    "bash",
    var.kubectl_context,
  ]
}

resource "aws_s3_object" "oidc_jwks" {
  bucket       = var.cdn_bucket
  key          = "${var.s3_prefix}/openid/v1/jwks"
  content      = data.external.oidc_jwks.result.result
  content_type = "application/json"
}

resource "aws_s3_object" "openid_configuration" {
  bucket = var.cdn_bucket
  key    = "${var.s3_prefix}/.well-known/openid-configuration"
  content = jsonencode(merge(
    jsondecode(data.external.openid_configuration.result.result),
    {
      issuer   = "https://${var.s3_prefix}"
      jwks_uri = "https://${var.s3_prefix}/openid/v1/jwks"
    },
  ))
  content_type = "application/json"
}
