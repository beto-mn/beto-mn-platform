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

  # Methods configuration
  http_methods = {
    post = {
      http_method      = "POST"
      authorization    = "NONE"
      api_key_required = true
      integration_type = "MOCK"
    }
    options = {
      http_method      = "OPTIONS"
      authorization    = "NONE"
      api_key_required = false
      integration_type = "MOCK"
    }
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

# Methods (POST and OPTIONS)
resource "aws_api_gateway_method" "contact" {
  for_each = local.http_methods

  rest_api_id      = aws_api_gateway_rest_api.contact_api.id
  resource_id      = aws_api_gateway_resource.contact.id
  http_method      = each.value.http_method
  authorization    = each.value.authorization
  api_key_required = each.value.api_key_required
}

# Integrations
resource "aws_api_gateway_integration" "contact" {
  for_each = local.http_methods

  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.contact[each.key].http_method
  type        = each.value.integration_type

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# Method responses
resource "aws_api_gateway_method_response" "contact_200" {
  for_each = local.http_methods

  rest_api_id         = aws_api_gateway_rest_api.contact_api.id
  resource_id         = aws_api_gateway_resource.contact.id
  http_method         = aws_api_gateway_method.contact[each.key].http_method
  status_code         = "200"
  response_parameters = local.cors_headers
}

# Integration responses
resource "aws_api_gateway_integration_response" "contact" {
  for_each = local.http_methods

  rest_api_id         = aws_api_gateway_rest_api.contact_api.id
  resource_id         = aws_api_gateway_resource.contact.id
  http_method         = aws_api_gateway_method.contact[each.key].http_method
  status_code         = aws_api_gateway_method_response.contact_200[each.key].status_code
  response_parameters = local.cors_values

  depends_on = [aws_api_gateway_integration.contact]
}

# Deployment
resource "aws_api_gateway_deployment" "contact_api" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.contact.id,
      [for method in aws_api_gateway_method.contact : method.id],
      [for integration in aws_api_gateway_integration.contact : integration.id],
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.contact
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
