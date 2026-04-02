# Domain identity verification
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "main" {
  domain = aws_ses_domain_identity.main.domain

  depends_on = [aws_route53_record.ses_dkim]
}

# SPF record — authorizes SES to send on behalf of the domain
resource "aws_route53_record" "ses_spf" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC record — tells receivers what to do if SPF/DKIM fail
resource "aws_route53_record" "ses_dmarc" {
  zone_id = var.hosted_zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=quarantine; adkim=s; aspf=s;"]
}

# Email templates
resource "aws_ses_template" "notification" {
  name    = "${var.project_name}-notification"
  subject = "📬 Nuevo mensaje de {{name}}"
  html    = file("${path.module}/templates/notification.html")
}

resource "aws_ses_template" "confirmation" {
  name    = "${var.project_name}-confirmation"
  subject = "¡Gracias por contactarme, {{name}}! 🚀"
  html    = file("${path.module}/templates/confirmation.html")
}
