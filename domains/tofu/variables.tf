variable "aws_execution_role_arn" {
  type        = string
  description = "Account-local OpenTofu execution role assumed by the AWS provider. Set null only while bootstrapping the execution roles."
  default     = "arn:aws:iam::869061964712:role/tofu-plan"
  nullable    = true

  validation {
    condition = var.aws_execution_role_arn == null || contains([
      "arn:aws:iam::869061964712:role/tofu-plan",
      "arn:aws:iam::869061964712:role/tofu-apply",
    ], var.aws_execution_role_arn)
    error_message = "aws_execution_role_arn must be null or the Domains account tofu-plan or tofu-apply role ARN."
  }
}

variable "ghilbut_txt_records_for_google" {
  type    = map(string)
  default = {}
}

variable "ghilbut_cname_records_for_google" {
  type    = map(object({ name = string, record = string }))
  default = {}
}

variable "ghilbut_dkim_for_root_domain" {
  type      = string
  default   = "v=DKIM1;k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCmu6k/9+YF2uIKN8n5nWD23v5Vci1vErg2Xqk6ReTLpzomtBJZ5+g315gvrgkj3KvS28R2GuqCmBmt+kmZhcTG6i0mUrrloQPjMxKHqdEMdmPxRtNdItn/8Jhb56jSr3i+Kg6YUq+yVYtz1IwFywAwzuRosU/Rct5CQQo03FePeQIDAQAB"
  sensitive = true
}

variable "cpa_oidc_thumbprint" {
  type        = string
  description = "SHA-1 thumbprint of the top intermediate CA for the CPA OIDC issuer TLS certificate."
  default     = "e7b8b5a6743ce1b2f17b041de59558a41472d70c"

  validation {
    condition     = can(regex("^[0-9a-f]{40}$", var.cpa_oidc_thumbprint))
    error_message = "cpa_oidc_thumbprint must use 40 lowercase hexadecimal characters."
  }
}
