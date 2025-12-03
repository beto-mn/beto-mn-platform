# S3 Module

This module creates and configures an S3 bucket for static website hosting with security best practices.

## Overview

The S3 module is designed specifically for hosting static websites (like Nuxt/Vue/React apps). It creates a bucket with public read access and optional website hosting configuration.

## Resources Created

### 1. `aws_s3_bucket` - Main Bucket

Creates the S3 bucket with a consistent naming pattern.

**Why?**
- Central storage for website files (HTML, CSS, JS, images)
- Bucket name must match domain name for custom domain routing
- Tags help with organization and cost tracking

### 2. `aws_s3_bucket_website_configuration` - Website Hosting

Enables S3 static website hosting features.

**Why?**
- `index_document`: Serves `index.html` when accessing root paths
- `error_document`: Routes all 404s to `index.html` for SPA client-side routing
- `count`: Only created when `enable_website_hosting = true` for flexibility

**SPA Routing:** Single Page Applications (Nuxt, React) handle routing client-side. When a user navigates to `/about`, S3 would normally return 404 since `/about/index.html` doesn't exist. By routing errors to `index.html`, the JavaScript app loads and handles the route.

### 3. `aws_s3_bucket_public_access_block` - Public Access

Allows public read access to the bucket.

**Why?**
- All settings set to `false` to permit public website access
- Without this, your website wouldn't be accessible to visitors
- Only affects read access; write access still requires authentication

### 4. `aws_s3_bucket_policy` - Bucket Policy

Grants public read permissions via IAM policy.

**Why?**
- `Principal: "*"` = Anyone on the internet
- `Action: s3:GetObject` = Only read/download, not write/delete
- `Resource: ".../*"` = Applies to all files in the bucket
- Works with public access block to enable website hosting

## Key Design Decisions

### No Versioning
**Decision:** Versioning is disabled

**Reason:** 
- Code is already versioned in Git
- Saves storage costs (no duplicate file history in S3)
- Simple deployment: just overwrite files

### No Encryption
**Decision:** Server-side encryption is not configured

**Reason:**
- Website content is public anyway
- No sensitive data stored
- Reduces complexity for a public website

### Conditional Website Configuration
**Decision:** Uses `count` parameter for website config

**Reason:**
- Module can be used for non-website buckets if needed
- Flexibility for different use cases
- Follows Terraform best practices

## Usage

```terraform
module "s3_website" {
  source = "./modules/s3"

  project_name           = "my-site"
  environment            = "prod"
  aws_region             = "us-east-1"
  bucket_name            = "example.com"  # Must match domain
  enable_website_hosting = true
}
```

## Important Notes

### Domain Name Requirement
The `bucket_name` **must exactly match** your domain name for custom domain routing to work with Route53:
- Domain: `example.com` → Bucket: `example.com`
- Domain: `www.example.com` → Bucket: `www.example.com`

### Deployment Workflow
```bash
# Build your static site
npm run generate

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
