output "certificate_arn" {
  description = "ARN of the validated certificate"
  value       = aws_acm_certificate.api.arn
}

output "certificate_domain" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.api.domain_name
}
