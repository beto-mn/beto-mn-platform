variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "api_subdomain" {
  description = "API subdomain (e.g., api-contact.example.com)"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the API domain"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN for API Gateway integration"
  type        = string
}

variable "lambda_function_arn" {
  description = "Lambda function ARN for API Gateway permission"
  type        = string
}
