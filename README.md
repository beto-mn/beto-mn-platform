# beto-mn-platform

This monorepo contains the complete infrastructure and Lambda function for the contact form API of the **beto-najera.com** portfolio website. All AWS resources are managed by Terraform.

## 🏗️ Structure

```
beto-mn-platform/
├── function/               → AWS Lambda function (TypeScript)
│   └── src/
│       └── handler.ts
│
├── infra/                  → Infrastructure as Code (Terraform)
│   └── modules/
│       ├── lambda/         → Lambda function + IAM role
│       ├── ses/            → SES email templates (notification + confirmation)
│       ├── api-gateway/    → REST API, stage, custom domain, API Key
│       ├── s3/             → Static website hosting
│       ├── cloudfront/     → CDN distribution
│       ├── route53/        → DNS management
│       └── acm/            → SSL certificates
│
└── .github/workflows/
    ├── terraform-plan.yml  → CI: lint, type-check, terraform plan (PRs)
    └── terraform-apply.yml → CD: build + terraform apply (merge to master)
```

---

## 🚀 Architecture

```
User Browser
    ↓
    ├─→ beto-najera.com
    │   CloudFront → S3 (Nuxt.js static site)
    │
    └─→ api-contact.beto-najera.com
        API Gateway (stage: api) → Lambda → SES
```

**Everything is managed by Terraform**, including the Lambda function. On every push to `master`, Terraform compiles the TypeScript, packages it, and deploys the function.

---

## 🔧 Local Development

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.10
- Node.js 22
- pnpm (`npm install -g pnpm`)

### Lambda Function

```bash
cd function

pnpm install       # install dependencies
pnpm lint          # ESLint
pnpm type-check    # TypeScript check
pnpm run build     # compile TypeScript → dist/
```

### Infrastructure

```bash
cd function && pnpm install && pnpm run build   # build first (required)

cd infra
terraform init
terraform plan
terraform apply
```

---

## 🚀 CI/CD Pipeline

Both workflows trigger on changes to `function/**` or `infra/**`.

| Workflow | Trigger | Steps |
|---|---|---|
| `terraform-plan.yml` | PR to master | lint → type-check → build → terraform plan → comment on PR |
| `terraform-apply.yml` | Merge to master | build → terraform apply |

### Required GitHub Configuration

**Secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
API_GATEWAY_KEY
```

**Variables:**
```
TF_VAR_AWS_REGION     = mx-central-1
TF_VAR_DOMAIN_NAME    = beto-najera.com
TF_VAR_EMAIL          = ing.betonajera@gmail.com
```

---

## 📦 What Terraform Manages

- ✅ S3 bucket for static website
- ✅ CloudFront distribution
- ✅ Route53 hosted zone and DNS records
- ✅ ACM certificates (CloudFront + API)
- ✅ API Gateway REST API with `/contact` endpoint, API Key, usage plan, custom domain
- ✅ Lambda function (IAM role, SES permissions, deployment package)
- ✅ SES email templates (`notification` → owner, `confirmation` → sender)

**Manual setup required:**
- SES email verification (`ing.betonajera@gmail.com` must be verified in us-east-1)
- IAM user for GitHub Actions (`beto-mn-github`)

---

## 🔐 Security

- API Key authentication on POST `/contact`
- Rate limiting: 1000 req/day, 5 req/sec burst
- HTTPS via ACM certificates
- Terraform state encrypted in S3
- IAM least privilege for Lambda and CI/CD user

---

## 💰 Cost Estimate

~**$0.50/month** (Route53 hosted zone). All other services stay within AWS Free Tier for a personal portfolio site.

---

## 🛠️ Common Tasks

```bash
# Get API key value
cd infra && terraform output api_key_value

# View all outputs
cd infra && terraform output

# View Lambda logs
aws logs tail /aws/lambda/beto-mn-site-contact --follow --region mx-central-1

# Destroy everything
cd infra && terraform destroy
```

---

## 🐛 Troubleshooting

**Terraform state lock**
```bash
cd infra
terraform force-unlock -force <lock-id>
```

**Certificate validation pending**
```bash
aws acm describe-certificate --certificate-arn <arn> --region mx-central-1
# DNS validation can take 20-30 minutes
```

**API Gateway resource already exists (409 on apply)**
```bash
# Get /contact resource ID
aws apigateway get-resources --rest-api-id <api-id> --region mx-central-1 \
  --query "items[?path=='/contact'].id" --output text

# Import into Terraform state
terraform import module.api_gateway.aws_api_gateway_method.contact_post <api-id>/<resource-id>/POST
terraform import module.api_gateway.aws_api_gateway_method.contact_options <api-id>/<resource-id>/OPTIONS
```

---

## 👤 Author

**Roberto Miron Nájera**
Portfolio: [beto-najera.com](https://beto-najera.com) · Email: ing.betonajera@gmail.com

## 📄 License

[MIT](LICENSE)
