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
  sensitive = true
}
