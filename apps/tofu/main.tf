module "awsra" {
  source = "./modules/awsra"

  name                            = "platform-core"
  trust_anchor_certificate_path   = "${path.module}/pki/issuers/awsra-issuing-ca/ca.crt.pem"
  certificate_subject_common_name = "awsra-for-k3s-cpa"
  vault_kms_key_arn               = aws_kms_key.vault.arn
}
