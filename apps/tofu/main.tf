module "awsra" {
  source = "./modules/awsra"

  name                            = var.name
  trust_anchor_certificate_path   = "${path.module}/pki/issuers/awsra-issuing-ca/ca.crt.pem"
  certificate_subject_common_name = "awsra-for-k3s-cpa"
  manifest_file_path              = "${path.module}/../argo-apps/vault/awsra.yaml"
  pkcs8_password_file_path        = "${path.module}/pki/.secrets/awsra-for-k3s-cpa.pass"
}

module "vault" {
  source = "./modules/vault"

  name               = var.name
  awsra_role_name    = "${var.name}-awsra"
  manifest_file_path = "${path.module}/../argo-apps/vault/vault.yaml"

  depends_on = [module.awsra]
}
