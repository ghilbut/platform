locals {
  vault_awsra_pkcs8_password_path = "${path.module}/pki/.secrets/awsra-for-k3s-cpa.pass"
  vault_awsra_pkcs8_password      = fileexists(local.vault_awsra_pkcs8_password_path) ? sensitive(trimspace(file(local.vault_awsra_pkcs8_password_path))) : null
}

resource "local_sensitive_file" "vault_awsra" {
  filename        = "${path.module}/../argo-apps/vault/awsra.yaml"
  file_permission = "0600"

  content = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "awsra"
      namespace = "vault"
    }
    type = "Opaque"
    stringData = {
      AWS_ROLESANYWHERE_PKCS8_PASSWORD   = local.vault_awsra_pkcs8_password
      AWS_ROLESANYWHERE_PROFILE_ARN      = module.awsra.profile_arn
      AWS_ROLESANYWHERE_ROLE_ARN         = module.awsra.role_arn
      AWS_ROLESANYWHERE_TRUST_ANCHOR_ARN = module.awsra.trust_anchor_arn
    }
  })

  lifecycle {
    precondition {
      condition     = local.vault_awsra_pkcs8_password != null
      error_message = "apps/tofu/pki/.secrets/awsra-for-k3s-cpa.pass is required to generate apps/argo-apps/vault/awsra.yaml."
    }
  }
}
