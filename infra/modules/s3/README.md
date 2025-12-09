# S3 Module

This module creates and configures an S3 bucket for static website hosting with public access and security best practices.

## Overview

The S3 module is designed specifically for hosting static websites (Nuxt.js, Vue.js, React, Angular, or plain HTML). It creates a bucket with public read access, configures website hosting features, and integrates with CloudFront or Route53 for custom domain support.

## Why S3 for Website Hosting?

S3 static website hosting is ideal for modern frontend applications:
- **Cost-Effective**: Extremely cheap ($0.023/GB/month storage, $0.09/GB transfer)
- **Scalable**: Handles traffic spikes automatically
- **Simple**: No servers to manage or patch
- **Fast**: Low latency from AWS's global infrastructure
- **Integrated**: Works seamlessly with CloudFront and Route53

## Resources Created

### 1. `aws_s3_bucket` - Main Storage Bucket

Creates the S3 bucket with a consistent naming pattern and tags.

**Why?**
- Central storage for all website files (HTML, CSS, JS, images, fonts)
- Bucket names must be globally unique across all AWS accounts
- Tags help with organization, cost tracking, and automation

**Configuration:**
```terraform
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Name      = var.bucket_name
    Project   = var.project_name
    Purpose   = "Static Website Hosting"
    ManagedBy = "Terraform"
  }
}
```

**Why these tags?**
- `Name`: Identifies bucket in AWS Console
- `Project`: Groups resources by project for cost allocation
- `Purpose`: Documents intent for future reference
- `ManagedBy`: Indicates infrastructure is managed by Terraform (don't manually modify)

**Bucket Naming:** While bucket names should ideally match domain names for direct S3 website hosting, this requirement is bypassed when using CloudFront (which is why we use `domain-name-site` format).

### 2. `aws_s3_bucket_website_configuration` - Website Hosting

Enables S3 static website hosting features with index and error document configuration.

**Why?**
- Transforms S3 from simple storage into a web server
- Handles HTTP requests and serves HTML files
- Provides website-specific endpoints (`bucket-name.s3-website.region.amazonaws.com`)

**Configuration:**
```terraform
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
```

**Why `index_document.suffix = "index.html"`?**
- Directory requests (`/about/`) automatically serve `/about/index.html`
- Root requests (`/`) automatically serve `/index.html`
- Standard web server behavior users expect

**Why `error_document.key = "index.html"`?**
Critical for **Single Page Applications (SPAs)**:

1. **Client-Side Routing Problem:**
   ```
   User navigates to: example.com/about
   S3 looks for: /about (file doesn't exist)
   S3 returns: 404 error ❌
   ```

2. **Solution:**
   ```
   User navigates to: example.com/about
   S3 looks for: /about (file doesn't exist)
   S3 returns: index.html instead (with 404 status code)
   SPA loads and JavaScript router handles /about ✅
   ```

**Without this setting:** Deep links and bookmarks break (404 errors)  
**With this setting:** All routes work perfectly

**Why conditional `count`?**
- Module can be used for non-website buckets (e.g., logs, backups)
- Flexibility for different use cases
- Pay only for what you need

### 3. `aws_s3_bucket_public_access_block` - Public Access Configuration

Configures public access settings to allow website hosting.

**Why?**
- By default, AWS blocks ALL public access to S3 buckets (security best practice)
- For website hosting, we need to allow public READ access
- These settings must be configured before the bucket policy takes effect

**Configuration:**
```terraform
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

**What each setting means:**

| Setting | Value | Meaning |
|---------|-------|---------|
| `block_public_acls` | false | Allow ACLs that grant public access |
| `block_public_policy` | false | Allow bucket policies that grant public access |
| `ignore_public_acls` | false | Don't ignore public ACLs (we want them to work) |
| `restrict_public_buckets` | false | Allow public bucket policies |

**Security Note:** All set to `false` is required for website hosting but increases security risk if you accidentally upload sensitive data. Always ensure you only upload public website files.

### 4. `aws_s3_bucket_policy` - Public Read Policy

Grants public read permissions via IAM policy.

**Why?**
- Makes all bucket objects publicly readable
- Required for website visitors to download HTML, CSS, JS, images
- Uses IAM policy language for fine-grained control

**Configuration:**
```terraform
resource "aws_s3_bucket_policy" "main" {
  count  = var.enable_website_hosting ? 1 : 0
  bucket = aws_s3_bucket.main.id

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
```

**Policy Breakdown:**

| Element | Value | Meaning |
|---------|-------|---------|
| `Sid` | PublicReadGetObject | Statement ID for documentation |
| `Effect` | Allow | Grant permission (not deny) |
| `Principal` | "*" | Anyone on the internet (anonymous access) |
| `Action` | s3:GetObject | Can read/download objects only (not list, delete, or write) |
| `Resource` | bucket-arn/* | Applies to all objects in the bucket |

**Why `depends_on`?**
- Public access block must be configured first
- Otherwise, policy creation fails with "access denied"
- Terraform dependency management ensures correct order

**Why only `s3:GetObject`?**
- Users can download files but can't:
  - List bucket contents (`s3:ListBucket`)
  - Upload files (`s3:PutObject`)
  - Delete files (`s3:DeleteObject`)
  - Modify permissions (`s3:PutBucketPolicy`)
- Minimum privilege principle for security

## Key Design Decisions

### No Versioning
**Decision:** S3 versioning is disabled

**Reasons:**
1. **Source Control:** Code already versioned in Git (source of truth)
2. **Cost Savings:** No duplicate file history stored in S3
3. **Simple Deployment:** Just overwrite files, no version management
4. **Build Artifacts:** Compiled static files are ephemeral (can rebuild from Git)

**Trade-off:** Can't rollback directly from S3, but can redeploy from Git instead.

### No Encryption at Rest
**Decision:** Server-side encryption not configured

**Reasons:**
1. **Public Data:** Website content is public anyway (defeats encryption purpose)
2. **No Sensitive Data:** Static websites don't contain secrets
3. **Simplicity:** Reduces configuration complexity
4. **Performance:** No encryption/decryption overhead

**When to add encryption:** If bucket stores private content or sensitive configuration files.

### No Lifecycle Policies
**Decision:** No automatic deletion or archival rules

**Reasons:**
1. **Static Content:** Website files don't age or expire
2. **Active Use:** All files actively served to users
3. **Manual Control:** Developers control what files exist
4. **Simplicity:** No complex lifecycle management needed

**When to add lifecycle:** If bucket stores logs or temporary files.

### No Logging
**Decision:** S3 access logging disabled

**Reasons:**
1. **CloudFront Logging:** When using CloudFront, use CloudFront logs instead
2. **Cost:** S3 logs cost money and can get large
3. **Analytics:** CloudFront or external analytics provide better insights
4. **Simplicity:** Reduces configuration and management overhead

**When to add logging:** Security audits, compliance requirements, or debugging access issues.

### Conditional Website Configuration
**Decision:** Uses `count` parameter for website-specific resources

**Reasons:**
1. **Reusability:** Module can create non-website buckets (logs, backups)
2. **Flexibility:** Different use cases with same module
3. **Best Practice:** Follow Terraform conditional resource pattern
4. **Cost Efficiency:** Don't enable unused features

## Usage

### Basic Static Website
```terraform
module "s3_website" {
  source = "./modules/s3"

  project_name           = "my-portfolio"
  aws_region             = "us-east-1"
  bucket_name            = "my-site-bucket"
  enable_website_hosting = true
}
```

### With CloudFront (Recommended)
```terraform
module "s3_website" {
  source = "./modules/s3"

  project_name           = "my-portfolio"
  aws_region             = "mx-central-1"
  bucket_name            = "example.com-site"  # Can be any name
  enable_website_hosting = true
}

module "cloudfront" {
  source = "./modules/cloudfront"
  
  s3_website_endpoint = module.s3_website.website_domain
  # ... other CloudFront config
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for tagging and organization | string | - | yes |
| aws_region | AWS region where bucket will be created | string | - | yes |
| bucket_name | Globally unique bucket name | string | - | yes |
| enable_website_hosting | Enable S3 website hosting features | bool | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | Bucket name (same as bucket_name) |
| bucket_arn | ARN of the S3 bucket |
| bucket_name | Name of the S3 bucket |
| website_endpoint | Website endpoint URL (with http://) |
| website_domain | Website domain (without http://) |
| website_hosted_zone_id | Hosted zone ID for Route53 alias records |

## Deployment Workflow

### 1. Build Your Static Site
```bash
# Nuxt.js
npm run generate

# React
npm run build

# Vue CLI
npm run build

# Angular
ng build --prod
```

### 2. Upload to S3
```bash
# Sync entire build folder
aws s3 sync ./dist s3://your-bucket-name/ --delete

# Upload single file
aws s3 cp index.html s3://your-bucket-name/
```

**Why `--delete` flag?**
- Removes old files no longer in build
- Keeps bucket clean
- Prevents serving stale content

### 3. Invalidate CloudFront (if using CDN)
```bash
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"
```

## Troubleshooting

### 403 Forbidden Error
**Symptoms:** Website shows "Access Denied" or 403 error

**Solutions:**
1. Check public access block settings (all should be `false`)
2. Verify bucket policy allows `s3:GetObject`
3. Ensure files have correct permissions (public-read)
4. Check CloudFront OAC configuration (if using CloudFront)

### 404 Not Found Error
**Symptoms:** Website shows 404 error page

**Solutions:**
1. Verify `index.html` exists in bucket root
2. Check website hosting is enabled
3. Confirm error document is set to `index.html` (for SPAs)
4. Test direct S3 website URL (not CloudFront) to isolate issue

### SPA Routes Don't Work
**Symptoms:** Direct navigation to routes shows 404, but clicking links works

**Solutions:**
1. Verify error document is set to `index.html`
2. Check CloudFront also has custom error response configured
3. Ensure SPA router is in history mode (not hash mode)

### Bucket Name Already Taken
**Symptoms:** Terraform fails with "bucket already exists"

**Solutions:**
1. Choose a different bucket name (must be globally unique)
2. Use a suffix (e.g., `example.com-site` instead of `example.com`)
3. Check if you own the bucket in another AWS account
4. If using CloudFront, bucket name doesn't need to match domain

## Security Considerations

### Public Read Access
- ✅ Only allows read operations (`s3:GetObject`)
- ✅ No list bucket permissions (can't enumerate files)
- ✅ No write/delete permissions
- ⚠️ All uploaded files become public (don't upload secrets!)

### Best Practices
1. **Never upload sensitive data** (API keys, passwords, tokens)
2. **Use environment variables** for configuration secrets
3. **Review file permissions** before uploading
4. **Monitor bucket policy** for unauthorized changes
5. **Enable MFA Delete** (if versioning enabled in future)
6. **Use CloudFront** for additional security layer

### Secure Deployment
```bash
# Build with production settings
NODE_ENV=production npm run generate

# Remove sensitive files before upload
rm -rf dist/.env dist/secrets.json

# Upload safely
aws s3 sync ./dist s3://bucket-name/ --delete
```

## Cost Optimization

### Storage Costs
- Standard S3: $0.023 per GB/month
- Typical website: 100 MB = $0.002/month (negligible)

### Transfer Costs
- First 1 GB/month: Free
- S3 to Internet: $0.09/GB
- S3 to CloudFront: $0.00 (free!)

**Recommendation:** Always use CloudFront to eliminate S3 transfer costs and improve performance.

# Deploy to S3
aws s3 sync .output/public/ s3://example.com/ --delete
```

The `--delete` flag removes old files not in the new build.

## Security Considerations

- ✅ Public read-only access (necessary for website)
- ✅ No public write access (secure)
- ✅ Bucket policy limits actions to GetObject only
- ⚠️ No HTTPS support directly (use CloudFront for HTTPS)

## Outputs

- `bucket_id` - Bucket name for deployments
- `bucket_arn` - For IAM policies
- `website_endpoint` - S3 website URL
- `website_domain` - Domain for Route53 ALIAS records
- `website_hosted_zone_id` - Zone ID for Route53 ALIAS records
