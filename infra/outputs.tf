output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3_website.bucket_id
}

output "s3_website_endpoint" {
  description = "S3 website endpoint URL"
  value       = module.s3_website.website_endpoint
}

output "domain_name" {
  description = "The domain name configured for the website"
  value       = module.route53.website_record_fqdn
}

output "route53_name_servers" {
  description = "Name servers for the Route53 hosted zone"
  value       = module.route53.hosted_zone_name_servers
}

output "api_endpoint" {
  description = "API Gateway default endpoint"
  value       = module.api_gateway.api_endpoint
}

output "api_custom_domain" {
  description = "API custom domain name"
  value       = module.api_gateway.custom_domain_name
}

output "api_id" {
  description = "API Gateway ID (use in Serverless)"
  value       = module.api_gateway.api_id
}

output "api_contact_resource_id" {
  description = "/contact resource ID (use in Serverless)"
  value       = module.api_gateway.contact_resource_id
}

output "api_key_value" {
  description = "API Key for frontend (use x-api-key header)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}
