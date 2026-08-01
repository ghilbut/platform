variable "bucket_regional_domain_name" { type = string }
variable "certificate_arn" { type = string }
variable "fqdns" { type = list(string) }
variable "lambda_function_arn" { type = string }
variable "name" { type = string }
variable "viewer_request_function_arn" { type = string }
