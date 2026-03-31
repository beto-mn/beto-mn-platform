variable "project_name" {
  description = "Project name for resource naming"
  type        = string
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

variable "notification_template" {
  description = "SES template name for owner notification"
  type        = string
}

variable "confirmation_template" {
  description = "SES template name for sender confirmation"
  type        = string
}
