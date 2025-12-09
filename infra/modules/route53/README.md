# Route53 Module

This module manages DNS configuration for website and API endpoints using AWS Route53, with support for both S3 direct hosting and CloudFront CDN.

## Overview

The Route53 module creates a hosted zone and configures DNS records to route traffic to your infrastructure. It's flexible enough to work with either direct S3 website hosting or CloudFront distributions, and includes optional www subdomain and API subdomain support.

## Why Route53?

Route53 is AWS's DNS service that integrates tightly with other AWS services:
- **ALIAS Records**: Point to AWS resources without CNAME limitations
- **Health Checks**: Automatic failover and monitoring
- **Low Latency**: Anycast network for fast DNS resolution
- **Integration**: Works seamlessly with S3, CloudFront, API Gateway

## Resources Created

### 1. `aws_route53_zone` - Hosted Zone

Creates the DNS hosted zone for your domain.

**Why?**
- Acts as the DNS authority for your domain
- Contains all DNS records for the domain
- Provides name servers that must be configured with your domain registrar
- Required for any DNS-based routing in AWS

**Tags:**
```terraform
tags = {
  Name = var.domain_name
}
```
Simple tagging for easy identification in AWS Console.

**Important:** After creation, you must update your domain's name servers (at the registrar) to point to the Route53 name servers.

### 2. `aws_route53_record.website` - Website DNS Record

Creates an A record (ALIAS) pointing to either CloudFront or S3 website endpoint.

**Why?**
- Routes `example.com` (or `www.example.com`) to your website
- Uses ALIAS record (AWS-specific) instead of CNAME for better performance
- No additional cost for ALIAS queries
- Supports both CloudFront and direct S3 hosting

**Conditional Logic - CloudFront vs S3:**
```terraform
alias {
  name                   = var.use_cloudfront ? var.cloudfront_domain_name : var.s3_website_domain
  zone_id                = var.use_cloudfront ? var.cloudfront_hosted_zone_id : var.s3_hosted_zone_id
  evaluate_target_health = false
}
```

**Why conditional?**
- **CloudFront Path**: Points to CloudFront distribution (most common for production)
- **S3 Direct Path**: Points directly to S3 website endpoint (simpler, but no CDN benefits)
- Single module handles both architectures

**Why `evaluate_target_health = false`?**
- CloudFront and S3 website endpoints have built-in redundancy
- Health checks not needed for these services
- Reduces unnecessary API calls

**Name Selection:**
```terraform
name = var.create_www_subdomain ? "www.${var.domain_name}" : var.domain_name
```
- `create_www_subdomain = false` → Creates record for `example.com`
- `create_www_subdomain = true` → Creates record for `www.example.com`

### 3. `aws_route53_record.root` - Root Domain Record (Optional)

Creates an additional A record for the root domain when using www subdomain.

**Why?**
- Only created when `create_www_subdomain = true`
- Ensures both `example.com` AND `www.example.com` work
- Both point to the same target (CloudFront or S3)
- Common pattern: root domain works, www works

**Conditional Creation:**
```terraform
count = var.create_www_subdomain ? 1 : 0
```
Uses Terraform `count` to conditionally create the resource.

**Use Case:**
```
User types: example.com → Routes to CloudFront/S3 ✅
User types: www.example.com → Routes to CloudFront/S3 ✅
```

### 4. `aws_route53_record.api` - API Subdomain Record (Optional)

Creates an A record for the API subdomain pointing to API Gateway.

**Why?**
- Routes `api-contact.example.com` to API Gateway
- Only created when `create_api_record = true`
- Separate subdomain keeps API and website concerns separated
- Uses regional API Gateway endpoint for lower latency

**Conditional Creation:**
```terraform
count = var.create_api_record ? 1 : 0
```
Only creates if API configuration is provided (optional feature).

**Why separate subdomain for API?**
1. **Security**: Can apply different firewall rules
2. **Rate Limiting**: Separate quotas from website
3. **CORS**: Easier to configure cross-origin requests
4. **Monitoring**: Separate metrics and alerts
5. **Caching**: Different caching strategies for API vs website

## Key Design Decisions

### Resource (Not Data Source)
**Decision:** Uses `resource` instead of `data` for hosted zone

**Reasons:**
1. **Clean Slate**: Domain purchased but hosted zone not yet created
2. **Infrastructure as Code**: Terraform manages the complete DNS infrastructure
3. **State Tracking**: Ensures hosted zone configuration is tracked
4. **Repeatability**: Can destroy and recreate cleanly

### ALIAS Records (Not CNAME)
**Decision:** Uses ALIAS records for AWS services

**Reasons:**
1. **Zone Apex Support**: ALIAS works at `example.com`, CNAME doesn't
2. **No Additional Costs**: ALIAS queries are free
3. **Better Performance**: AWS-optimized routing, lower latency
4. **Health Checks**: Supports automatic failover
5. **AWS Integration**: Works seamlessly with CloudFront, S3, ALB, API Gateway

**CNAME Limitations:**
```
❌ example.com CNAME cloudfront.net  # Not allowed at zone apex
✅ example.com ALIAS cloudfront.net  # Allowed with ALIAS
```

### Flexible Architecture Support
**Decision:** Single module supports both CloudFront and direct S3

**Reasons:**
1. **Code Reuse**: Don't need separate modules for each architecture
2. **Easy Migration**: Switch from S3 to CloudFront by changing one variable
3. **Consistency**: Same DNS configuration regardless of backend
4. **Maintainability**: Single source of truth for DNS logic

### Optional Resources with Count
**Decision:** Uses `count` for optional records (www, API)

**Reasons:**
1. **Flexibility**: Not every deployment needs www or API
2. **Cost Efficiency**: Pay only for what you use
3. **Incremental Deployment**: Start simple, add complexity later
4. **Cleaner Code**: No need for separate modules

## Usage

### CloudFront Setup (Recommended for Production)
```terraform
module "route53" {
  source = "./modules/route53"

  domain_name                = "example.com"
  use_cloudfront             = true
  cloudfront_domain_name     = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id  = module.cloudfront.distribution_hosted_zone_id
  create_www_subdomain       = true
  create_api_record          = false
}
```

### Direct S3 Setup (Simpler, No CDN)
```terraform
module "route53" {
  source = "./modules/route53"

  domain_name          = "example.com"
  use_cloudfront       = false
  s3_website_domain    = module.s3.website_domain
  s3_hosted_zone_id    = module.s3.website_hosted_zone_id
  create_www_subdomain = true
  create_api_record    = false
}
```

### With API Subdomain
```terraform
module "route53" {
  source = "./modules/route53"

  domain_name                = "example.com"
  use_cloudfront             = true
  cloudfront_domain_name     = module.cloudfront.distribution_domain_name
  cloudfront_hosted_zone_id  = module.cloudfront.distribution_hosted_zone_id
  create_www_subdomain       = true
  create_api_record          = true
  api_subdomain              = "api-contact.example.com"
  api_gateway_domain         = module.api.custom_domain_regional_domain_name
  api_gateway_zone_id        = module.api.custom_domain_regional_zone_id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain_name | The domain name for the website | string | - | yes |
| use_cloudfront | Use CloudFront instead of direct S3 | bool | false | no |
| cloudfront_domain_name | CloudFront distribution domain name | string | "" | conditional* |
| cloudfront_hosted_zone_id | CloudFront hosted zone ID (Z2FDTNDATAQYW2) | string | "" | conditional* |
| s3_website_domain | S3 website endpoint domain | string | "" | conditional** |
| s3_hosted_zone_id | S3 hosted zone ID for the region | string | "" | conditional** |
| create_www_subdomain | Create www subdomain | bool | true | no |
| create_api_record | Create API subdomain DNS record | bool | false | no |
| api_subdomain | API subdomain name | string | "" | conditional*** |
| api_gateway_domain | API Gateway regional domain name | string | "" | conditional*** |
| api_gateway_zone_id | API Gateway hosted zone ID | string | "" | conditional*** |

\* Required when `use_cloudfront = true`  
\** Required when `use_cloudfront = false`  
\*** Required when `create_api_record = true`

## Outputs

| Name | Description |
|------|-------------|
| hosted_zone_id | Route53 hosted zone ID (use in ACM module) |
| hosted_zone_name_servers | Name servers for domain registrar configuration |
| website_record_fqdn | Fully qualified domain name of website record |

## Post-Deployment Steps

### 1. Get Name Servers
After `terraform apply`, get the name servers:
```bash
terraform output route53_name_servers
```

Output example:
```
[
  "ns-1234.awsdns-56.org",
  "ns-789.awsdns-12.co.uk",
  "ns-345.awsdns-67.com",
  "ns-890.awsdns-34.net"
]
```

### 2. Update Domain Registrar
Go to your domain registrar (where you bought the domain) and update the name servers to match the Route53 name servers.

**Common Registrars:**
- **Amazon Route 53**: Domains → Select domain → "Add or edit name servers"
- **GoDaddy**: Domain Settings → Nameservers → Change → Custom
- **Namecheap**: Domain List → Manage → Nameservers → Custom DNS
- **Google Domains**: DNS → Name servers → Use custom name servers

### 3. Wait for Propagation
DNS changes can take 24-48 hours to fully propagate, but typically complete in 1-2 hours.

**Check propagation:**
```bash
dig @8.8.8.8 example.com
nslookup example.com 8.8.8.8
```

## Troubleshooting

### Domain Not Resolving
**Symptoms:** `dig example.com` returns no answer

**Solutions:**
1. Verify name servers at registrar match Route53 name servers
2. Wait longer (DNS propagation can take time)
3. Clear local DNS cache:
   ```bash
   # macOS
   sudo dscacheutil -flushcache
   
   # Windows
   ipconfig /flushdns
   
   # Linux
   sudo systemd-resolve --flush-caches
   ```

### Wrong Target
**Symptoms:** Domain resolves but shows wrong content

**Solutions:**
1. Check Route53 record points to correct target (CloudFront vs S3)
2. Verify target service is working (test CloudFront/S3 URL directly)
3. Check ALIAS record zone ID matches target service

### API Subdomain Not Working
**Symptoms:** `api-contact.example.com` doesn't resolve

**Solutions:**
1. Verify `create_api_record = true`
2. Check API Gateway custom domain is created
3. Ensure API Gateway domain variables are correct

## Security Considerations

- ✅ DNSSEC support available (optional)
- ✅ Query logging for audit trails (optional)
- ✅ ALIAS records prevent DNS enumeration attacks
- ✅ Separate subdomains isolate API from website

### 3. Wait for Propagation
DNS propagation can take 24-48 hours, but often completes in a few hours.

### 4. Verify DNS
```bash
dig example.com
nslookup example.com
```

## DNS Resolution Flow

```
User types: example.com
    ↓
Browser queries DNS
    ↓
Domain registrar → Route53 name servers
    ↓
Route53 hosted zone → A record (ALIAS)
    ↓
ALIAS points to S3 website endpoint
    ↓
Browser connects to S3
    ↓
Website loads
```

## Important Notes

### Name Server Configuration
**Critical:** You MUST update your domain's name servers at the registrar. The Route53 hosted zone won't work until the domain delegation is complete.

### Propagation Time
DNS changes take time to propagate globally. Be patient after making changes.

### S3 Bucket Naming
The S3 bucket name must exactly match the domain name in the DNS record for routing to work properly.

## Troubleshooting

### DNS Not Resolving
1. Verify name servers are updated at registrar
2. Wait for DNS propagation (up to 48 hours)
3. Check Route53 hosted zone has correct records
4. Use `dig` or `nslookup` to debug

### Website Not Loading
1. Verify S3 bucket name matches domain
2. Check S3 bucket policy allows public access
3. Ensure S3 website hosting is enabled
4. Test S3 website endpoint directly first

## Outputs

- `hosted_zone_id` - For other resources to use
- `hosted_zone_name_servers` - For domain registrar configuration
- `website_record_fqdn` - Fully qualified domain name for website
- `root_record_fqdn` - Root domain FQDN (if created)
