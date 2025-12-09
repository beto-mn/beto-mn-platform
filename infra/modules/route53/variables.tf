variable "domain_name" {
  description = "The domain name for the website (must be registered in Route53)"
  type        = string
}

variable "use_cloudfront" {
  description = "Use CloudFront instead of direct S3 website endpoint"
  type        = bool
  default     = false
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
  default     = ""
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (Z2FDTNDATAQYW2)"
  type        = string
  default     = ""
}

variable "s3_website_domain" {
  description = "The S3 website endpoint domain"
  type        = string
  default     = ""
}

variable "s3_hosted_zone_id" {
  description = "The S3 hosted zone ID for the region"
  type        = string
  default     = ""
}

variable "create_www_subdomain" {
  description = "Create www subdomain pointing to the same S3 bucket"
  type        = bool
  default     = true
}

variable "create_api_record" {
  description = "Create API subdomain DNS record"
  type        = bool
  default     = false
}

variable "api_subdomain" {
  description = "API subdomain name (e.g., api-contact)"
  type        = string
  default     = ""
}

variable "api_gateway_domain" {
  description = "API Gateway regional domain name"
  type        = string
  default     = ""
}

variable "api_gateway_zone_id" {
  description = "API Gateway hosted zone ID"
  type        = string
  default     = ""
}
