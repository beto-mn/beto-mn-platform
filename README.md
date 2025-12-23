# beto-mn-platform

This monorepo contains the complete backend infrastructure and Lambda function for the contact form API of the **beto-najera.com** portfolio website.

## 🏗️ Monorepo Structure

This project is organized as a monorepo with two main directories:

```
beto-mn-platform/
├── function/         → AWS Lambda function (Node.js + pnpm)
│   ├── src/
│   │   └── handler.ts
│   ├── package.json
│   ├── pnpm-lock.yaml
│   └── serverless.yml
│
├── infra/            → Infrastructure as Code (Terraform)
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
├── .github/
│   ├── workflows/
│   │   ├── terraform-plan.yml    → Plan on PRs
│   │   ├── terraform-apply.yml   → Apply on main
│   │   ├── function-ci.yml       → Test function on PRs
│   │   └── function-deploy.yml   → Deploy function on main
│   ├── CODEOWNERS
│   └── pull_request_template.md
│
└── README.md         → This file
```

### Why a Monorepo?

- **Single source of truth:** Infrastructure and application code live together
- **Simplified dependency management:** Lambda function and API Gateway definitions stay in sync
- **Easier deployment:** Deploy infrastructure first, then Lambda function
- **Better version control:** Track infra and code changes in one place
- **Automated CI/CD:** GitHub Actions workflows for both infrastructure and function

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

### `/function` - Lambda Function

The Lambda function handles contact form submissions:

- **Language:** Node.js + TypeScript
- **Package Manager:** pnpm
- **Framework:** Serverless Framework
- **Purpose:** Process form data, validate inputs, send email via SES
- **Deployment:** Automated via GitHub Actions on merge to `main`

**Key Features:**
- Form validation
- Rate limiting (via API Gateway)
- Email notifications via AWS SES
- Error handling and logging

### `/infra` - Infrastructure as Code

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
- ❌ Lambda function (deployed separately by Serverless Framework via GitHub Actions)
- ❌ SES email configuration (manual setup required)
- ❌ CI/CD credentials (IAM user created manually)

[Full Documentation →](./infra/README.md)

---

## 🚀 CI/CD Pipeline

This project uses **GitHub Actions** for automated deployments with a **short-lived branch strategy**:

### Workflows

**Terraform:**
- `terraform-plan.yml` - Runs on PRs, comments plan output
- `terraform-apply.yml` - Runs on merge to `main`, applies changes

**Lambda Function:**
- `function-ci.yml` - Runs on PRs, tests and lints code
- `function-deploy.yml` - Runs on merge to `main`, deploys to AWS

### Required GitHub Configuration

**Secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
API_GATEWAY_KEY
```

**Variables:**
```
TF_VAR_AWS_REGION
TF_VAR_DOMAIN_NAME
API_GATEWAY_ID
API_GATEWAY_ROOT_ID
```

**Environment:**
- Name: `production`
- Optional reviewers for extra protection

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b fix/validation-bug

# 2. Make changes
vim function/src/handler.ts

# 3. Push (triggers CI checks)
git push -u origin fix/validation-bug

# 4. Create PR
gh pr create --fill

# 5. Review terraform plan and test results in PR

# 6. Merge (triggers automatic deployment)
gh pr merge --squash
```

---

## 🔧 Local Development

### Prerequisites

```bash
# Install pnpm
npm install -g pnpm

# Install Terraform
brew install terraform

# Configure AWS credentials
aws configure
```

### Working with Infrastructure

```bash
cd infra

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Working with Lambda Function

```bash
cd function

# Install dependencies
pnpm install

# Run tests
pnpm test

# Lint code
pnpm lint

# Type check
pnpm type-check

# Build
pnpm build
```

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
- **Node.js** 20+
- **pnpm** (`npm install -g pnpm`)
- **Serverless Framework** (`pnpm add -g serverless`)

### AWS Requirements:
- AWS account with appropriate permissions
- IAM user for GitHub Actions (manually created)
- Domain name registered (for Route53)
- SES email verified (for sending notifications)

### GitHub Configuration:
- Repository secrets and variables configured
- `production` environment created
- (Optional) Branch protection on `main`

---

## 🔐 Security Features

- ✅ **API Key Authentication:** Only authorized requests can POST to `/contact`
- ✅ **Rate Limiting:** 1000 requests/day, 5 req/sec to prevent abuse
- ✅ **CORS:** Properly configured for browser security
- ✅ **HTTPS:** SSL certificates via ACM
- ✅ **Remote State:** Terraform state encrypted in S3
- ✅ **IAM Permissions:** Least privilege for Lambda execution and CI/CD
- ✅ **GitHub Secrets:** AWS credentials protected in GitHub
- ✅ **Environment Protection:** Manual approval for production deployments (optional)

---

## 💰 Cost Estimation

### AWS Free Tier (First 12 months):
- **Route53:** $0.50/month (hosted zone)
- **S3:** Free (< 5GB, 20k requests)
- **API Gateway:** Free (< 1M requests)
- **Lambda:** Free (< 1M requests)
- **ACM:** Free (AWS-managed certificates)
- **CloudFront:** Free (< 50GB, 2M requests)

**Expected: ~$0.50/month** for personal portfolio site

---

## 🛠️ Common Tasks

### Get API Key and IDs
```bash
cd infra
terraform output api_key_value
terraform output api_gateway_id
terraform output api_gateway_root_resource_id
```

### View Infrastructure State
```bash
cd infra
terraform show
```

### Update Lambda Code (Manual)
```bash
cd function
pnpm install
serverless deploy
```

### View Lambda Logs
```bash
cd function
serverless logs -f sendEmail --tail
```

### Destroy Everything
```bash
# Destroy Lambda
cd function
serverless remove

# Destroy infrastructure
cd infra
terraform destroy
```

---

## 📚 Additional Resources

- [Terraform Infrastructure Guide](./infra/README.md) - Complete infrastructure documentation
- [GitHub Actions Workflows](./.github/workflows/) - CI/CD pipeline details
- [AWS API Gateway Module](./infra/modules/api-gateway/README.md) - API Gateway documentation

---

## 🐛 Troubleshooting

### Infrastructure Issues

**Issue:** Terraform state lock
```bash
# Force unlock (use with caution)
cd infra
terraform force-unlock <lock-id>
```

**Issue:** Certificate validation pending
```bash
# Check certificate status
aws acm describe-certificate --certificate-arn <arn>

# DNS records may take 20-30 minutes to propagate
```

### CI/CD Issues

**Issue:** Workflow fails with "No value for required variable"
- Check that all GitHub Variables are set correctly
- Verify variable names match exactly

**Issue:** Terraform plan shows unexpected changes
- Someone may have modified resources manually in AWS
- Check for state drift
- Consider running `terraform refresh`

**Issue:** Lambda deployment fails
- Verify `API_GATEWAY_ID` and `API_GATEWAY_ROOT_ID` variables are set
- Check IAM user permissions
- Review Serverless Framework logs

---

## 👤 Author

**Alberto Najera**
- GitHub: [@beto-mn](https://github.com/beto-mn)
- Website: [beto-najera.com](https://beto-najera.com)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
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
