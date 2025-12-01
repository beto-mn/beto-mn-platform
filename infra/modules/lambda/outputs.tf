output "invoke_arn" {
  description = "Lambda function invoke ARN for API Gateway integration"
  value       = aws_lambda_function.contact.invoke_arn
}

output "function_arn" {
  description = "Lambda function ARN for API Gateway permission"
  value       = aws_lambda_function.contact.arn
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.contact.function_name
}
