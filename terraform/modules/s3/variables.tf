# S3 Module - Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket (will be prefixed with project_name)"
  type        = string
  default     = "bucket"
}

variable "enable_website_hosting" {
  description = "Enable static website hosting for the bucket"
  type        = bool
  default     = false
}
