# beto-mn-contact-api

This monorepo contains the complete backend infrastructure and Lambda function for the contact form API of the **beto-najera.com** portfolio website.

## 🏗️ Monorepo Structure

This project is organized as a monorepo with two main directories:

```
beto-mn-contact-api/
├── backend/          → AWS Lambda function (Node.js + TypeScript)
│   ├── src/
│   │   └── handler.ts
│   ├── package.json
│   ├── serverless.yml
│   └── README.md
│
├── terraform/        → Infrastructure as Code (S3, Route53, ACM, API Gateway)
│   ├── modules/
│   │   ├── s3/           → Static website hosting
│   │   ├── route53/      → DNS management
│   │   ├── acm/          → SSL certificates
│   │   └── api-gateway/  → REST API structure
│   ├── backend.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── modules.tf
│   ├── outputs.tf
│   └── README.md
│
└── README.md         → This file
```

### Why a Monorepo?

- **Single source of truth:** Infrastructure and application code live together
- **Simplified dependency management:** Lambda function and API Gateway definitions stay in sync
- **Easier deployment:** Deploy infrastructure first, then Lambda function
- **Better version control:** Track infra and code changes in one place

---

## 🚀 Architecture Overview

```
User Browser
    ↓
    ├─→ beto-najera.com (S3 Static Website)
    │   └─→ Route53 DNS + Website Hosting
    │
    └─→ api-contact.beto-najera.com (API Gateway)
        ├─→ ACM SSL Certificate
        ├─→ API Key Authentication
        ├─→ CORS + Rate Limiting
        └─→ AWS Lambda (Contact Handler)
            └─→ AWS SES (Email Notification)
```

### Components:

1. **Static Website (Nuxt.js)** - Hosted on S3, served via custom domain
2. **DNS Management** - Route53 handles domain routing
3. **SSL Certificates** - ACM provides HTTPS for API subdomain
4. **REST API** - API Gateway with `/contact` endpoint, API Key auth, and CORS
5. **Lambda Function** - Node.js handler for form processing and email sending

---

## 📦 Directory Details

### `/backend` - Lambda Function

The Lambda function handles contact form submissions:

- **Language:** Node.js + TypeScript
- **Framework:** Serverless Framework
- **Purpose:** Process form data, validate inputs, send email via SES
- **Deployment:** `serverless deploy` (after Terraform creates API structure)

**Key Features:**
- Form validation
- Rate limiting (via API Gateway)
- Email notifications via AWS SES
- Error handling and logging

[Full Documentation →](./backend/README.md)

### `/terraform` - Infrastructure as Code

Terraform manages all AWS infrastructure in a modular architecture:

**Modules:**
- **`s3/`** - Static website hosting for Nuxt app
- **`route53/`** - DNS hosted zone and A records
- **`acm/`** - SSL certificates with DNS validation
- **`api-gateway/`** - REST API structure, API Key, usage plans, custom domain

**Configuration Files:**
- `backend.tf` - S3 remote state storage
- `provider.tf` - AWS provider with default tags
- `variables.tf` - Global variables (region, domain, project name)
- `modules.tf` - Module composition and wiring
- `outputs.tf` - Exported values (nameservers, API key, endpoints)

**What Terraform Creates:**
- ✅ S3 bucket for static website hosting
- ✅ Route53 hosted zone with DNS records
- ✅ ACM certificate for API subdomain
- ✅ API Gateway REST API with `/contact` endpoint
- ✅ API Key and Usage Plan (100 req/day, 5 req/sec)
- ✅ Custom domain for API with SSL

**What Terraform Does NOT Create:**
- ❌ Lambda function (deployed separately by Serverless Framework)
- ❌ SES email configuration (manual setup required)

[Full Documentation →](./terraform/README.md)

---

## 🚀 Deployment Workflow

### Step 1: Deploy Infrastructure (Terraform)

```bash
cd terraform

# Setup AWS credentials
source ./setup-aws-creds.sh

# Create S3 backend bucket (one-time)
aws s3api create-bucket \
  --bucket beto-mn-contact-api-terraform-state \
  --region mx-central-1 \
  --create-bucket-configuration LocationConstraint=mx-central-1

# Initialize and apply
terraform init
terraform plan
terraform apply
```

**This creates:**
- S3 website bucket
- Route53 hosted zone
- ACM certificate
- API Gateway structure (with MOCK integration)

**Save these outputs:**
```bash
terraform output route53_name_servers  # Update at domain registrar
terraform output api_key_value          # Use in frontend
```

### Step 2: Deploy Lambda Function (Serverless)

```bash
cd backend

# Install dependencies
npm install

# Deploy Lambda
serverless deploy
```

**This creates:**
- Lambda function with contact handler
- Updates API Gateway integration (MOCK → Lambda)
- Sets up Lambda permissions

### Step 3: Configure Domain

1. Update nameservers at your domain registrar with Route53 nameservers
2. Wait for DNS propagation (24-48 hours)
3. Verify DNS: `dig beto-najera.com`

### Step 4: Deploy Frontend

```bash
# Build Nuxt app
npm run generate

# Upload to S3
aws s3 sync .output/public/ s3://beto-najera.com/ --delete
```

---

## 🔧 Development Workflow

### Making Infrastructure Changes

```bash
cd terraform

# Make changes to .tf files
terraform plan    # Review changes
terraform apply   # Apply changes
```

### Updating Lambda Function

```bash
cd backend

# Update handler code
# ...

# Redeploy
serverless deploy
```

### Testing API Locally

```bash
cd backend

# Run serverless offline
serverless offline
```

---

## 📋 Prerequisites

### Required Tools:
- **AWS CLI** configured with credentials
- **Terraform** >= 1.0
- **Node.js** 18+ (for Lambda)
- **Serverless Framework** (`npm install -g serverless`)

### AWS Requirements:
- AWS account with appropriate permissions
- Domain name registered (for Route53)
- SES email verified (for sending notifications)

---

## 🔐 Security Features

- ✅ **API Key Authentication:** Only authorized requests can POST to `/contact`
- ✅ **Rate Limiting:** 100 requests/day, 5 req/sec to prevent abuse
- ✅ **CORS:** Properly configured for browser security
- ✅ **HTTPS:** SSL certificates via ACM
- ✅ **Remote State:** Terraform state encrypted in S3
- ✅ **IAM Permissions:** Least privilege for Lambda execution

---

## 💰 Cost Estimation

### AWS Free Tier (First 12 months):
- **Route53:** $0.50/month (hosted zone)
- **S3:** Free (< 5GB, 20k requests)
- **API Gateway:** Free (< 1M requests)
- **Lambda:** Free (< 1M requests)
- **ACM:** Free (AWS-managed certificates)

**Expected: ~$0.50/month** for personal portfolio site

---

## 🛠️ Common Tasks

### Get API Key
```bash
cd terraform
terraform output api_key_value
```

### View Infrastructure State
```bash
cd terraform
terraform show
```

### Update Lambda Code
```bash
cd backend
serverless deploy function -f contact
```

### View Lambda Logs
```bash
cd backend
serverless logs -f contact --tail
```

### Destroy Everything
```bash
# Destroy Lambda
cd backend
serverless remove

# Destroy infrastructure
cd ../terraform
terraform destroy
```

---

## 📚 Documentation

- [Terraform Infrastructure Guide](./terraform/README.md) - Complete infrastructure documentation
- [Lambda Function Guide](./backend/README.md) - Backend development guide
- [S3 Module](./terraform/modules/s3/README.md) - Static website hosting
- [Route53 Module](./terraform/modules/route53/README.md) - DNS management
- [ACM Module](./terraform/modules/acm/README.md) - SSL certificates
- [API Gateway Module](./terraform/modules/api-gateway/README.md) - REST API configuration

---

## 🐛 Troubleshooting

### Infrastructure Issues
See [Terraform README Troubleshooting](./terraform/README.md#-troubleshooting)

### Lambda Issues
- Check CloudWatch logs in AWS Console
- Use `serverless logs -f contact --tail`
- Verify SES email is verified

### API Issues
- Verify API Key is correct
- Check CORS headers in browser console
- Ensure Usage Plan limits not exceeded

---

## 📝 License

[MIT](LICENSE) - Open source and free to use

---

## 👤 Author

**Roberto Miron Nájera**  
Backend Developer — TypeScript, Node.js, AWS, Terraform

Portfolio: [beto-najera.com](https://beto-najera.com)  
Email: ing.betonajera@gmail.com
