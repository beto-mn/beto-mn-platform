data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.root}/../function/dist"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.project_name}-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ses" {
  name = "${var.project_name}-lambda-ses-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "contact" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.project_name}-contact"
  role             = aws_iam_role.lambda.arn
  handler          = "src/handler.main"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 90

  environment {
    variables = {
      NODE_OPTIONS            = "--enable-source-maps"
      FROM_EMAIL              = var.email
      OWNER_EMAIL             = var.email
      SES_REGION              = var.ses_region
      NOTIFICATION_TEMPLATE   = var.notification_template
      CONFIRMATION_TEMPLATE   = var.confirmation_template
    }
  }

  tags = {
    Name = "${var.project_name}-contact"
  }
}
