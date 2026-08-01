module "awsra" {
  source = "./modules/awsra"

  name                            = var.name
  trust_anchor_certificate_path   = "${path.module}/pki/issuers/awsra-issuing-ca/ca.crt.pem"
  certificate_subject_common_name = "awsra-for-k3s-cpa"
}

module "vault" {
  source = "./modules/vault"

  name            = var.name
  awsra_role_name = module.awsra.role_name
}
