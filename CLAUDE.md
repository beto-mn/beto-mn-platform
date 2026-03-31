# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a serverless monorepo for the beto-najera.com portfolio website. It contains:
- **`/function`** — AWS Lambda contact form handler (TypeScript + Serverless Framework)
- **`/infra`** — AWS infrastructure (Terraform with 5 modules: s3, cloudfront, route53, acm, api-gateway)

Remote state is stored in S3 bucket `beto-mn-contact-api-terraform-state`.

## Architecture

```
User → CloudFront (CDN) → S3 (Nuxt.js static site)
User → Route53 → api-contact.beto-najera.com → API Gateway → Lambda (POST /contact)
```

**Lambda flow:** API Gateway receives POST `/contact` with `x-api-key` header → invokes Lambda → `handler.main` parses JSON body → returns response.

**Dual-region AWS setup:**
- Primary: `mx-central-1` (Lambda, API Gateway, S3, Route53, ACM regional cert)
- Global: `us-east-1` (ACM cert for CloudFront — required by AWS)

**API Gateway** is externally managed (not created by Serverless Framework). The `serverless.ts` attaches to an existing REST API using hardcoded IDs (`restApiId`, `restApiRootResourceId`). The actual IDs are overridden at deploy time via GitHub Actions vars (`API_GATEWAY_ID`, `API_GATEWAY_ROOT_ID`).

## Key Files

- `function/src/handler.ts` — Lambda handler (`main` export), processes contact form POSTs
- `function/src/index.ts` — Serverless function definition (path/method/auth config)
- `function/serverless.ts` — Serverless Framework config (runtime, region, API Gateway attachment)
- `infra/modules.tf` — Wires all 5 Terraform modules together
- `infra/provider.tf` — Dual-provider setup (mx-central-1 + us-east-1)
- `infra/outputs.tf` — Exports `api_id` and `api_root_resource_id` needed for function deployment
