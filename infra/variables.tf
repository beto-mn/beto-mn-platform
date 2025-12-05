variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "beto-mn-site"
}

variable "domain_name" {
  description = "Domain name for the website (must be registered in Route53)"
  type        = string
}

variable "bucket_suffix" {
  description = "Unique suffix for S3 bucket name (since beto-najera.com is globally taken)"
  type        = string
  default     = "site"
}

variable "api_subdomain" {
  description = "API subdomain (will be prefixed to domain_name)"
  type        = string
  default     = "api-contact"
}
