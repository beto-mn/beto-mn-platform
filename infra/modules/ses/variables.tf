variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "domain_name" {
  description = "Domain to verify in SES"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS verification records"
  type        = string
}
