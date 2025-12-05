# S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Name      = var.bucket_name
    Project   = var.project_name
    Purpose   = "Static Website Hosting"
    ManagedBy = "Terraform"
  }
}

# Static website configuration
resource "aws_s3_bucket_website_configuration" "main" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Public access configuration for website hosting
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access for website
resource "aws_s3_bucket_policy" "main" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.main.id

  # Ensure public access block is configured first
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}
