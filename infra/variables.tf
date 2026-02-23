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

variable "email" {
  description = "SES verified email address (used as sender and notification recipient)"
  type        = string
}

variable "ses_region" {
  description = "AWS region where SES is configured"
  type        = string
  default     = "us-east-1"
}
