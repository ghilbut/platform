variable "acm_domain_name" { type = string }
variable "fqdns" { type = list(string) }
variable "name" { type = string }
variable "repo" { type = string }
variable "zones" { type = map(map(any)) }
