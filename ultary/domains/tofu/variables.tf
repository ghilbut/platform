variable "aws_profile" {
  type    = string
  default = "ultary-domains"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "core"
}

variable "root_domain" {
  type    = string
  default = "ultary.co"
}

variable "ultary_co_dkim_for_root_domain" {
  type      = string
  sensitive = true
}

variable "ultary_co_txt_for_sub_domains" {
  type = map(string)
}

variable "ultary_co_cname_for_sub_domains" {
  type      = map(object({ name = string, record = string }))
  sensitive = true
}

variable "ultary_co_dkim_for_sub_domains" {
  type      = map(string)
  sensitive = true
}
