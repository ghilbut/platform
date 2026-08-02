output "lambda_function_arn" { value = aws_lambda_function.this.qualified_arn }
output "lambda_function_base_arn" { value = aws_lambda_function.this.arn }
output "lambda_role_arn" { value = aws_iam_role.lambda.arn }
output "viewer_request_function_arn" { value = aws_cloudfront_function.viewer_request.arn }
