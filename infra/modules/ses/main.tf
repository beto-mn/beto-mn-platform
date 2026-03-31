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
