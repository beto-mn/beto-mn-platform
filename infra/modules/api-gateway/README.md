# API Gateway Module

This module creates a complete API Gateway REST API with CORS support, API Key authentication, usage limits, and custom domain configuration for contact form submissions.

## Overview

The API Gateway module sets up a production-ready REST API with a single `/contact` endpoint. It includes rate limiting, CORS for browser requests, mock integration (for Serverless Lambda deployment), and custom domain with SSL certificate support.

## Resources Created

### Configuration Locals

```terraform
locals {
  cors_headers = { ... }
  cors_values = { ... }
  http_methods = {
    post    = { ... }
    options = { ... }
  }
}
```

**Why?**
- **DRY Principle:** Define CORS configuration once, reuse everywhere
- **Maintainability:** Change CORS settings in one place
- **Scalability:** Easy to add more HTTP methods (GET, PUT, DELETE)

**HTTP Methods Map:**
- `post`: Main endpoint requiring API Key
- `options`: CORS preflight without API Key (browsers send this automatically)

### 1. `aws_api_gateway_rest_api` - REST API

Creates the base API Gateway REST API.

**Why?**
- `endpoint_configuration.types = ["REGIONAL"]`: API hosted in specific region (not globally distributed)
- Regional is cheaper and sufficient for most use cases
- Alternatives: `EDGE` (CloudFront-backed, global), `PRIVATE` (VPC-only)

### 2. `aws_api_gateway_resource` - /contact Path

Creates the `/contact` resource (path) in the API.

**Why?**
- `parent_id = root_resource_id`: Nested under root (`/`)
- `path_part = "contact"`: Creates `/contact` path
- Resources represent URL paths in REST APIs

**Full URL:** `https://api.example.com/stage/contact`

### 3. `aws_api_gateway_method` - HTTP Methods (with for_each)

Creates POST and OPTIONS methods for the `/contact` endpoint.

**Why `for_each`?**
```terraform
resource "aws_api_gateway_method" "contact" {
  for_each = local.http_methods
  
  http_method      = each.value.http_method       # "POST" or "OPTIONS"
  api_key_required = each.value.api_key_required  # true for POST, false for OPTIONS
}
```

- **Eliminates duplication:** One resource definition creates both methods
- **POST:** Requires API Key for security
- **OPTIONS:** No API Key (CORS preflight must be public)

**CORS Preflight:** When browsers make cross-origin POST requests, they first send an OPTIONS request to check if CORS is allowed. This must succeed before the actual POST is sent.

### 4. `aws_api_gateway_integration` - Backend Integration

Connects HTTP methods to backend (Lambda, HTTP, etc.).

**Why `type = "MOCK"`?**
- Temporary placeholder integration
- Serverless Framework will replace this with actual Lambda integration
- Mock returns success without calling any backend
- Allows infrastructure to be created before Lambda code is ready

**Serverless will change this to:**
```yaml
type: AWS_PROXY  # Lambda proxy integration
uri: Lambda function ARN
```

### 5. `aws_api_gateway_method_response` - Response Configuration

Defines what HTTP responses the method can return.

**Why?**
- `status_code = "200"`: Success response
- `response_parameters = local.cors_headers`: Declares CORS headers are allowed
- Gateway validates responses match this configuration

**CORS Headers:**
- `Access-Control-Allow-Origin`: Which domains can call the API
- `Access-Control-Allow-Headers`: Which request headers are permitted
- `Access-Control-Allow-Methods`: Which HTTP methods are allowed

### 6. `aws_api_gateway_integration_response` - Response Mapping

Transforms backend responses before returning to client.

**Why?**
- `response_parameters = local.cors_values`: Adds actual CORS header values
- `'*'` for Allow-Origin: Permits any domain (adjust for production)
- Headers included in every response
- `depends_on`: Ensures integration exists first

**CORS Values:**
- `Allow-Origin: '*'`: Accept requests from any website (or specify your domain)
- `Allow-Headers`: Includes `X-Api-Key` for API Key authentication
- `Allow-Methods: 'POST,OPTIONS'`: Only these methods supported

### 7. `aws_api_gateway_deployment` - API Deployment

Creates a deployment snapshot of the API configuration.

**Why?**
```terraform
triggers = {
  redeployment = sha1(jsonencode([...]))
}
```
- **Automatic redeployment:** When any configuration changes, redeploys automatically
- **SHA1 hash:** Detects changes in method, integration, or resource configuration
- **for loops:** Dynamically includes all methods created via for_each

```terraform
lifecycle {
  create_before_destroy = true
}
```
- **Zero downtime:** New deployment created before old one destroyed
- Prevents API outages during updates

### 8. `aws_api_gateway_stage` - API Stage

Creates a named stage (environment) for the API.

**Why?**
- `stage_name = "api"`: Fixed stage name (not environment-based)
- Stage name appears in URL: `https://domain.com/api/contact`
- Tags for organization and cost tracking

**Deployment vs Stage:**
- **Deployment:** Snapshot of API configuration
- **Stage:** Named pointer to a deployment (e.g., `dev`, `prod`, `api`)

### 9. `aws_api_gateway_domain_name` - Custom Domain

Configures custom domain for the API instead of AWS-generated URL.

**Why?**
- **User-friendly:** `api-contact.example.com` vs `abc123.execute-api.region.amazonaws.com`
- **Professional:** Branded domain
- **Certificate:** Requires SSL certificate ARN from ACM module
- **Regional:** Matches API endpoint type

**Without custom domain:**
```
https://abc123.execute-api.mx-central-1.amazonaws.com/api/contact
```

**With custom domain:**
```
https://api-contact.example.com/api/contact
```

### 10. `aws_api_gateway_base_path_mapping` - Domain Mapping

Maps custom domain to the API stage.

**Why?**
- Connects `api-contact.example.com` → API Gateway stage
- Routes requests from custom domain to correct API and stage
- Enables the custom domain to actually work

### 11. `aws_api_gateway_api_key` - API Key

Creates an API Key for authentication.

**Why?**
- **Authentication:** Only requests with valid API Key can access endpoint
- **Rate limiting:** Usage is tracked per API Key
- AWS generates key value automatically
- `enabled = true`: Key is active and can be used

### 12. `aws_api_gateway_usage_plan` - Usage Limits

Defines rate limits and quotas for API usage.

**Why?**
```terraform
quota_settings {
  limit  = 100    # Maximum 100 requests per day
  period = "DAY"
}
```
- **Prevents abuse:** Stops spam/bot attacks
- **Cost control:** Limits unexpected usage
- **Quota:** Total requests allowed per period

```terraform
throttle_settings {
  burst_limit = 5   # Max 5 simultaneous requests
  rate_limit  = 2   # Average 2 requests/second
}
```
- **Rate limiting:** Prevents rapid-fire requests
- **Burst:** Allows brief spikes
- **Protects backend:** Lambda won't be overwhelmed

**Use Case for Contact Form:**
- Normal user submits 1-2 forms per day ✅
- Bot trying to spam 1000 requests ❌ Blocked after 100

### 13. `aws_api_gateway_usage_plan_key` - Key Association

Links API Key to Usage Plan.

**Why?**
- API Keys alone don't enforce limits
- Usage Plan defines limits
- This resource activates limits for the API Key
- Without this, Usage Plan has no effect

## Key Design Decisions

### For_Each for HTTP Methods
**Decision:** Use `for_each` with local map for methods

**Reasons:**
- Eliminates ~60% of code duplication
- Single source of truth for CORS configuration
- Easy to add more methods (GET, DELETE, etc.)
- Cleaner and more maintainable

### Mock Integration
**Decision:** Use MOCK instead of Lambda integration

**Reasons:**
- Infrastructure and application code deployed separately
- Terraform creates API structure
- Serverless Framework adds Lambda later
- Prevents tight coupling between infra and code

### Fixed Stage Name
**Decision:** `stage_name = "api"` instead of variable

**Reasons:**
- Single environment (no dev/staging/prod distinction needed)
- Cleaner URLs for personal website
- Reduces complexity
- `environment` variable only used for tags

### API Key Required
**Decision:** POST requires API Key, OPTIONS doesn't

**Reasons:**
- **Security:** Prevents unauthorized POST requests
- **CORS compatibility:** OPTIONS must be public (browser requirement)
- **Rate limiting:** Track usage per API Key
- **Cost control:** Prevent abuse

### Regional Endpoint
**Decision:** Use REGIONAL not EDGE

**Reasons:**
- Lower cost (EDGE uses CloudFront)
- Sufficient performance for single-region traffic
- Simpler configuration
- Adequate for personal website traffic

## Usage

```terraform
module "api_gateway" {
  source = "./modules/api-gateway"

  project_name    = "my-site"
  environment     = "prod"
  api_subdomain   = "api-contact.example.com"
  certificate_arn = module.acm_api.certificate_arn
}
```

## Frontend Integration

### JavaScript Fetch Example
```javascript
async function sendContactForm(data) {
  const response = await fetch('https://api-contact.example.com/api/contact', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': 'YOUR_API_KEY_HERE'  // From terraform output
    },
    body: JSON.stringify(data)
  });
  
  return response.json();
}
```

### Getting API Key
```bash
terraform output api_key_value
```

Store API Key in environment variable, not in code:
```javascript
const apiKey = process.env.NUXT_PUBLIC_API_KEY;
```

## Serverless Framework Integration

After Terraform creates the API, Serverless deploys the Lambda:

```yaml
# serverless.yml
provider:
  apiGateway:
    restApiId: !ImportValue ApiGatewayId       # From Terraform output
    restApiRootResourceId: !ImportValue ContactResourceId

functions:
  contact:
    handler: handler.contact
    events:
      - http:
          path: contact
          method: post
          # Serverless updates the integration from MOCK to Lambda
```

## Rate Limiting Behavior

### Normal Usage ✅
```
User submits form → 1 request
5 minutes later → 1 request
Total: 2 requests/day → Within quota (100)
```

### Bot Attack ❌
```
Bot sends 10 requests/second
  → Only 5 pass (burst_limit)
  → Rest throttled
After 100 total requests → Quota exceeded
  → All requests blocked until next day
```

## Important Notes

### API Key Security
- Don't commit API Key to Git
- Use environment variables in frontend
- Rotate keys periodically
- Monitor usage in AWS Console

### CORS Configuration
Current setting `'*'` allows any origin. For production, specify your domain:
```terraform
"method.response.header.Access-Control-Allow-Origin" = "'https://example.com'"
```

### Deployment Order
1. Terraform creates API structure (this module)
2. Serverless deploys Lambda function
3. Serverless updates integration from MOCK to Lambda

## Outputs

- `api_id` - For Serverless configuration
- `api_endpoint` - Default AWS endpoint
- `custom_domain_name` - Your custom domain
- `api_key_value` - For frontend (sensitive)
- `contact_resource_id` - For Serverless configuration

## Cost Considerations

### Free Tier (First 12 months)
- 1 million API calls/month free
- Beyond free tier: $3.50 per million requests

### Your Expected Usage (Contact Form)
- ~100-1000 requests/month
- Cost: $0.00 (well within free tier)

### If Exceeded Free Tier
- 10,000 requests = $0.035 (~3 cents)
- Very cost-effective
