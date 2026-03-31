output "notification_template_name" {
  description = "SES template name for owner notification"
  value       = aws_ses_template.notification.name
}

output "confirmation_template_name" {
  description = "SES template name for sender confirmation"
  value       = aws_ses_template.confirmation.name
}
