# API Gateway Module - Outputs

output "api_id" {
  description = "The ID of the REST API"
  value       = aws_api_gateway_rest_api.contact_api.id
}

output "api_arn" {
  description = "The ARN of the REST API"
  value       = aws_api_gateway_rest_api.contact_api.arn
}

output "api_endpoint" {
  description = "The default endpoint URL for the API"
  value       = aws_api_gateway_stage.contact_api.invoke_url
}

output "api_stage_name" {
  description = "The stage name"
  value       = aws_api_gateway_stage.contact_api.stage_name
}

output "custom_domain_name" {
  description = "The custom domain name"
  value       = aws_api_gateway_domain_name.contact_api.domain_name
}

output "custom_domain_regional_domain_name" {
  description = "The regional domain name for Route53"
  value       = aws_api_gateway_domain_name.contact_api.regional_domain_name
}

output "custom_domain_regional_zone_id" {
  description = "The regional zone ID for Route53"
  value       = aws_api_gateway_domain_name.contact_api.regional_zone_id
}

output "contact_resource_id" {
  description = "The ID of the /contact resource (for Serverless integration)"
  value       = aws_api_gateway_resource.contact.id
}

output "api_key_id" {
  description = "The API Key ID"
  value       = aws_api_gateway_api_key.contact_api.id
}

output "api_key_value" {
  description = "The API Key value (use in your frontend)"
  value       = aws_api_gateway_api_key.contact_api.value
  sensitive   = true
}
