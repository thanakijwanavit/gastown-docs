# Gas Town Documentation Deployment

## Overview

The Gas Town documentation site is deployed to **docs.gt.villamarket.ai** using:
- **S3 Bucket**: `docs.gt.villamarket.ai`
- **CloudFront**: CDN with URL rewrite function
- **GitHub Actions**: Automated deployment on push to master/main

## Current Status

| Component | Status | Details |
|-----------|--------|---------|
| Site URL | ✅ Live | https://docs.gt.villamarket.ai |
| Build | ✅ Working | `npm run build` succeeds |
| S3 Bucket | ✅ Configured | docs.gt.villamarket.ai |
| CloudFront | ✅ Active | CloudFront distribution serving content |
| CloudFront Function | ✅ Deployed | URL rewrite for trailing slashes |

## Deployment Methods

### 1. Automated Deployment (GitHub Actions)

The primary deployment method is via GitHub Actions:

**File**: `.github/workflows/deploy.yml`

**Triggers**: Push to `master` or `main` branches

**Steps**:
1. Checkout code
2. Setup Node.js 20
3. Install dependencies (`npm ci`)
4. Validate documentation (`npm test` — frontmatter, links, sidebar positions)
5. Build website (`npm run build`)
6. Validate search index (`npm run test:search` — document count, key terms, URLs)
7. Configure AWS credentials
8. Deploy to S3 with cache headers
9. Deploy/update CloudFront Function
10. Invalidate CloudFront cache

**Required Secrets**:
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `CF_DIST_ID` - CloudFront Distribution ID

### 2. Manual Deployment

Use the deploy script:

```bash
# Set required environment variable
export CF_DIST_ID=E1234567890

# Run deploy script
./scripts/deploy.sh
```

**Prerequisites**:
- AWS CLI configured with appropriate credentials
- `CF_DIST_ID` environment variable set

## Build Process

```bash
# Install dependencies
npm install

# Build for production
npm run build

# Output directory: build/
```

The build process:
1. Runs `build-llm-txt.js` to generate LLM access files (`llm.txt`, `llm-full.txt`)
2. Runs Docusaurus build to generate static site in `build/`

## S3 Deployment Details

The deployment uses two sync operations for optimal caching:

### Static Assets (long cache)
```bash
aws s3 sync build/ s3://docs.gt.villamarket.ai/ \
  --delete \
  --cache-control "public, max-age=3600" \
  --exclude "*.html" \
  --exclude "sitemap.xml" \
  --exclude "llm.txt" \
  --exclude "llm-full.txt"
```

### HTML/Dynamic Files (short cache)
```bash
aws s3 sync build/ s3://docs.gt.villamarket.ai/ \
  --cache-control "public, max-age=300" \
  --exclude "*" \
  --include "*.html" \
  --include "sitemap.xml" \
  --include "llm.txt" \
  --include "llm-full.txt" \
  --include "api/*"
```

## CloudFront Configuration

### URL Rewrite Function

**Name**: `gastown-docs-url-rewrite`
**Runtime**: `cloudfront-js-2.0`

Handles:
- `/docs` → 301 redirect to `/docs/`
- `/docs/` → `/docs/index.html`

**File**: `cloudfront/url-rewrite.js`

### Cache Invalidation

After each deployment, the CloudFront cache is invalidated:
```bash
aws cloudfront create-invalidation \
  --distribution-id $CF_DIST_ID \
  --paths "/*"
```

## Blockers for ga-jmqs

**Issue**: AWS credentials secrets not configured in GitHub

**Required Secrets** (to be added to GitHub repository):
1. `AWS_ACCESS_KEY_ID` - AWS IAM access key with S3 and CloudFront permissions
2. `AWS_SECRET_ACCESS_KEY` - Corresponding secret key
3. `CF_DIST_ID` - CloudFront Distribution ID

**AWS IAM Permissions Required**:
- `s3:PutObject`
- `s3:DeleteObject`
- `s3:ListBucket`
- `cloudfront:CreateInvalidation`
- `cloudfront:DescribeFunction`
- `cloudfront:CreateFunction`
- `cloudfront:UpdateFunction`
- `cloudfront:PublishFunction`

## Verification

Check deployment status:
```bash
# Check headers
curl -I https://docs.gt.villamarket.ai

# Should show:
# - HTTP/2 200
# - server: AmazonS3
# - via: CloudFront
# - NOT: SimpleHTTP
```

## Alternative: GitHub Pages

There's also a GitHub Pages workflow (`.github/workflows/pages.yml`) for deploying to GitHub Pages as a backup/alternative.

## Local Development

```bash
# Start dev server
npm start

# Build for production
npm run build

# Serve built files locally
npm run serve
```
