moved {
  from = aws_s3_bucket.state
  to   = aws_s3_bucket.state["legacy"]
}

moved {
  from = aws_s3_bucket_ownership_controls.state
  to   = aws_s3_bucket_ownership_controls.state["legacy"]
}

moved {
  from = aws_s3_bucket_public_access_block.state
  to   = aws_s3_bucket_public_access_block.state["legacy"]
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.state
  to   = aws_s3_bucket_server_side_encryption_configuration.state["legacy"]
}

moved {
  from = aws_s3_bucket_versioning.state
  to   = aws_s3_bucket_versioning.state["legacy"]
}

moved {
  from = aws_s3_bucket_policy.state
  to   = aws_s3_bucket_policy.state["legacy"]
}
