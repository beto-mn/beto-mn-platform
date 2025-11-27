locals {
  cors_headers = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  cors_values = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
}

# REST API
resource "aws_api_gateway_rest_api" "contact_api" {
  name        = "${var.project_name}-contact-api"
  description = "Contact form API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /contact resource
resource "aws_api_gateway_resource" "contact" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  parent_id   = aws_api_gateway_rest_api.contact_api.root_resource_id
  path_part   = "contact"
}

# POST method
resource "aws_api_gateway_method" "contact_post" {
  rest_api_id      = aws_api_gateway_rest_api.contact_api.id
  resource_id      = aws_api_gateway_resource.contact.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# OPTIONS method (CORS preflight)
resource "aws_api_gateway_method" "contact_options" {
  rest_api_id      = aws_api_gateway_rest_api.contact_api.id
  resource_id      = aws_api_gateway_resource.contact.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

# POST integration (Lambda proxy)
resource "aws_api_gateway_integration" "contact_post" {
  rest_api_id             = aws_api_gateway_rest_api.contact_api.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.contact_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# OPTIONS integration (MOCK for CORS)
resource "aws_api_gateway_integration" "contact_options" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

# OPTIONS method response (CORS headers)
resource "aws_api_gateway_method_response" "contact_options_200" {
  rest_api_id         = aws_api_gateway_rest_api.contact_api.id
  resource_id         = aws_api_gateway_resource.contact.id
  http_method         = aws_api_gateway_method.contact_options.http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

# OPTIONS integration response (CORS values)
resource "aws_api_gateway_integration_response" "contact_options" {
  rest_api_id         = aws_api_gateway_rest_api.contact_api.id
  resource_id         = aws_api_gateway_resource.contact.id
  http_method         = aws_api_gateway_method.contact_options.http_method
  status_code         = aws_api_gateway_method_response.contact_options_200.status_code
  response_parameters = local.cors_values

  depends_on = [aws_api_gateway_integration.contact_options]
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.contact_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "contact_api" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contact.id,
      aws_api_gateway_method.contact_post.id,
      aws_api_gateway_method.contact_options.id,
      aws_api_gateway_integration.contact_post.id,
      aws_api_gateway_integration.contact_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.contact_post,
    aws_api_gateway_integration.contact_options,
  ]
}

# Stage
resource "aws_api_gateway_stage" "contact_api" {
  deployment_id = aws_api_gateway_deployment.contact_api.id
  rest_api_id   = aws_api_gateway_rest_api.contact_api.id
  stage_name    = "api"

  tags = {
    Name = "${var.project_name}-contact-api"
  }
}

# Custom domain name
resource "aws_api_gateway_domain_name" "contact_api" {
  domain_name              = var.api_subdomain
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = var.api_subdomain
  }
}

# Base path mapping
resource "aws_api_gateway_base_path_mapping" "contact_api" {
  api_id      = aws_api_gateway_rest_api.contact_api.id
  stage_name  = aws_api_gateway_stage.contact_api.stage_name
  domain_name = aws_api_gateway_domain_name.contact_api.domain_name
}

# API Key
resource "aws_api_gateway_api_key" "contact_api" {
  name    = "${var.project_name}-contact-api-key"
  enabled = true

  tags = {
    Name = "${var.project_name}-contact-api-key"
  }
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "contact_api" {
  name        = "${var.project_name}-contact-api-plan"
  description = "Usage plan for contact API"

  api_stages {
    api_id = aws_api_gateway_rest_api.contact_api.id
    stage  = aws_api_gateway_stage.contact_api.stage_name
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 10
    rate_limit  = 5
  }

  tags = {
    Name = "${var.project_name}-contact-api-plan"
  }
}

# Associate API Key with Usage Plan
resource "aws_api_gateway_usage_plan_key" "contact_api" {
  key_id        = aws_api_gateway_api_key.contact_api.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.contact_api.id
}
