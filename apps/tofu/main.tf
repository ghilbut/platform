locals {
  vault_manifest_directory_path = coalesce(var.vault_manifest_directory_path, "${path.module}/../argo-apps/vault")
}

module "awsra" {
  source = "./modules/awsra"

  name                            = var.name
  trust_anchor_certificate_path   = "${path.module}/pki/issuers/awsra-issuing-ca/ca.crt.pem"
  certificate_subject_common_name = "awsra-for-k3s-cpa"
  manifest_directory_path         = local.vault_manifest_directory_path
  pkcs8_password_file_path        = "${path.module}/pki/.secrets/awsra-for-k3s-cpa.pass"
  pkcs8_password_revision         = var.awsra_pkcs8_password_revision
  leaf_certificate_path           = "${path.module}/pki/leaves/awsra-for-k3s-cpa/awsra-for-k3s-cpa.crt.pem"
  leaf_private_key_path           = "${path.module}/pki/leaves/awsra-for-k3s-cpa/awsra-for-k3s-cpa.key.pem"
}

module "vault" {
  source = "./modules/vault"

  name                    = var.name
  awsra_role_name         = "${var.name}-awsra"
  manifest_directory_path = local.vault_manifest_directory_path

  depends_on = [module.awsra]
}
