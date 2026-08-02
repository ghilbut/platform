variable "bucket_name" {
  type        = string
  description = "Name of the CDN origin bucket"
}

variable "error_page_files" {
  type        = map(string)
  description = "S3 object key to local error page file path"
}

variable "name" {
  type        = string
  description = "Short CDN identifier used in Name tags"
}

variable "repo" { type = string }
