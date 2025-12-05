# S3 Module - Static Website Hosting for Nuxt App
module "s3_website" {
  source = "./modules/s3"

  project_name           = var.project_name
  aws_region             = var.aws_region
  bucket_name            = "${var.domain_name}-${var.bucket_suffix}"
  enable_website_hosting = true
}

# ACM Module - SSL Certificate for API
module "acm_api" {
  source = "./modules/acm"

  domain_name    = "${var.api_subdomain}.${var.domain_name}"
  hosted_zone_id = module.route53.hosted_zone_id
}

# API Gateway Module - Contact API
module "api_gateway" {
  source = "./modules/api-gateway"

  project_name    = var.project_name
  api_subdomain   = "${var.api_subdomain}.${var.domain_name}"
  certificate_arn = module.acm_api.certificate_arn
}

# Route53 Module - DNS Configuration
module "route53" {
  source = "./modules/route53"

  domain_name          = var.domain_name
  s3_website_domain    = module.s3_website.website_domain
  s3_hosted_zone_id    = module.s3_website.website_hosted_zone_id
  create_www_subdomain = true
  create_api_record    = true
  api_subdomain        = "${var.api_subdomain}.${var.domain_name}"
  api_gateway_domain   = module.api_gateway.custom_domain_regional_domain_name
  api_gateway_zone_id  = module.api_gateway.custom_domain_regional_zone_id
}
