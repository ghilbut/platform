locals {
  default_tags = merge(var.default_tags, {
    "opentofu/module/repo" = var.repo
    "opentofu/module/path" = "aws/cdn/tofu/modules/cloudfront/"
  })
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.name}-cdn-oac"
  description                       = "OAC for ${var.name} CDN S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  aliases             = var.fqdns
  comment             = "${var.name} CDN"
  wait_for_deployment = false

  origin {
    origin_id                = "s3-cdn"
    domain_name              = var.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-cdn"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = []
      cookies { forward = "none" }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = var.viewer_request_function_arn
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = var.lambda_function_arn
      include_body = false
    }
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 503
    response_code         = 503
    response_page_path    = "/503.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(local.default_tags, { Name = "${var.name}-cdn" })
}
