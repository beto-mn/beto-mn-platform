# S3 Module - Static Website Hosting for Nuxt App
module "s3_website" {
  source = "./modules/s3"

  project_name           = var.project_name
  aws_region             = var.aws_region
  bucket_name            = "${var.domain_name}-${var.bucket_suffix}"
  enable_website_hosting = true
}

# ACM Module - SSL Certificate for CloudFront (must be in us-east-1)
module "acm_cloudfront" {
  source = "./modules/acm"
  providers = {
    aws = aws.us_east_1
  }

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  hosted_zone_id            = module.route53.hosted_zone_id
}

# CloudFront Module - CDN for Static Website
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name        = var.project_name
  domain_name         = var.domain_name
  s3_bucket_name      = module.s3_website.bucket_name
  s3_website_endpoint = module.s3_website.website_domain
  certificate_arn     = module.acm_cloudfront.certificate_arn
  create_www_alias    = true
}

# ACM Module - SSL Certificate for API (regional)
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

  domain_name                = var.domain_name
  use_cloudfront             = true
  cloudfront_domain_name     = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id  = module.cloudfront.distribution_hosted_zone_id
  s3_website_domain          = module.s3_website.website_domain
  s3_hosted_zone_id          = module.s3_website.website_hosted_zone_id
  create_www_subdomain       = true
  create_api_record          = true
  api_subdomain              = "${var.api_subdomain}.${var.domain_name}"
  api_gateway_domain         = module.api_gateway.custom_domain_regional_domain_name
  api_gateway_zone_id        = module.api_gateway.custom_domain_regional_zone_id
}
