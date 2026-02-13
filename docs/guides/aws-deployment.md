---
title: "AWS Deployment Guide"
sidebar_position: 8
description: "Deploy Gas Town documentation site to AWS using S3, CloudFront, and Route 53 with the villaai profile."
---

# AWS Deployment Guide

This guide covers deploying the Gas Town documentation site to AWS infrastructure using S3 for static hosting, CloudFront for CDN, and Route 53 for DNS.

---

## Overview

The Gas Town documentation is a static site built with Docusaurus and deployed to:

- **S3 Bucket** (`docs.gt.villamarket.ai`) — Static website hosting
- **CloudFront Distribution** — Global CDN with edge caching
- **Route 53** — DNS management
- **CloudFront Functions** — URL rewriting for trailing slashes

---

## Prerequisites

### AWS CLI Setup

Install and configure the AWS CLI with the `villaai` profile:

```bash
# Install AWS CLI
brew install awscli

# Configure the villaai profile
aws configure --profile villaai
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region name: us-east-1
# Default output format: json
```

### Required AWS Permissions

Your IAM user or role needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:PutBucketPolicy",
        "s3:GetBucketPolicy"
      ],
      "Resource": [
        "arn:aws:s3:::docs.gt.villamarket.ai",
        "arn:aws:s3:::docs.gt.villamarket.ai/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:CreateFunction",
        "cloudfront:UpdateFunction",
        "cloudfront:PublishFunction",
        "cloudfront:DescribeFunction",
        "cloudfront:GetFunction"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Infrastructure Setup

### 1. Create S3 Bucket

```bash
aws s3api create-bucket \
  --bucket docs.gt.villamarket.ai \
  --region us-east-1 \
  --profile villaai

# Enable static website hosting
aws s3 website s3://docs.gt.villamarket.ai/ \
  --index-document index.html \
  --error-document 404.html \
  --profile villaai

# Set bucket policy for public read access
aws s3api put-bucket-policy \
  --bucket docs.gt.villamarket.ai \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::docs.gt.villamarket.ai/*"
      }
    ]
  }' \
  --profile villaai
```

### 2. Create CloudFront Distribution

```bash
# Get the S3 website endpoint
S3_WEBSITE_ENDPOINT="docs.gt.villamarket.ai.s3-website-us-east-1.amazonaws.com"

# Create CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name "$S3_WEBSITE_ENDPOINT" \
  --default-root-object index.html \
  --profile villaai
```

Or use the AWS Console:

1. Go to **CloudFront** → **Create Distribution**
2. **Origin Domain**: Select your S3 bucket website endpoint
3. **Viewer Protocol Policy**: Redirect HTTP to HTTPS
4. **Allowed HTTP Methods**: GET, HEAD, OPTIONS
5. **Cache Policy**: CachingOptimized
6. **Default Root Object**: `index.html`
7. **Error Pages**: 
   - HTTP Error Code: 403 → Custom Error Response: /404.html, Response Code: 404
   - HTTP Error Code: 404 → Custom Error Response: /404.html, Response Code: 404

### 3. Configure CloudFront Function for URL Rewriting

The CloudFront function handles trailing slashes for Docusaurus:

```javascript
// cloudfront/url-rewrite.js
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // If URI ends with '/', append index.html
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    // If URI has no file extension, redirect to trailing slash
    else if (!uri.split('/').pop().includes('.')) {
        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: uri + '/' }
            }
        };
    }

    return request;
}
```

Deploy the function:

```bash
aws cloudfront create-function \
  --name gastown-docs-url-rewrite \
  --function-config '{
    "Comment": "URL rewrite for Docusaurus trailing slash",
    "Runtime": "cloudfront-js-2.0"
  }' \
  --function-code fileb://cloudfront/url-rewrite.js \
  --profile villaai

# Get the function ARN and attach it to your distribution
FUNCTION_ARN=$(aws cloudfront list-functions --profile villaai \
  --query "FunctionList.Items[?Name=='gastown-docs-url-rewrite'].FunctionMetadata.FunctionARN" \
  --output text)

echo "Function ARN: $FUNCTION_ARN"
```

### 4. Configure Route 53 DNS

```bash
# Get your CloudFront distribution domain name
CF_DOMAIN=$(aws cloudfront list-distributions --profile villaai \
  --query "DistributionList.Items[?Aliases.Items[?@=='docs.gt.villamarket.ai']].DomainName" \
  --output text)

# Create A record alias (requires hosted zone ID)
HOSTED_ZONE_ID="YOUR_HOSTED_ZONE_ID"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "docs.gt.villamarket.ai",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "'"$CF_DOMAIN"'",
          "EvaluateTargetHealth": false
        }
      }
    }]
  }' \
  --profile villaai
```

---

## Automated Deployment

The project includes a GitHub Actions workflow for automated deployment (`.github/workflows/deploy.yml`).

### GitHub Secrets Required

Set these secrets in your GitHub repository:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for villaai profile |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for villaai profile |
| `CF_DIST_ID` | CloudFront Distribution ID |

### Manual Deployment

Deploy from your local machine:

```bash
# 1. Build the site
cd gastowndocs
npm ci
npm run build

# 2. Deploy to S3 with villaai profile
aws s3 sync build/ s3://docs.gt.villamarket.ai/ \
  --delete \
  --cache-control "public, max-age=3600" \
  --exclude "*.html" \
  --exclude "sitemap.xml" \
  --exclude "llm.txt" \
  --exclude "llm-full.txt" \
  --profile villaai

aws s3 sync build/ s3://docs.gt.villamarket.ai/ \
  --cache-control "public, max-age=300" \
  --exclude "*" \
  --include "*.html" \
  --include "sitemap.xml" \
  --include "llm.txt" \
  --include "llm-full.txt" \
  --include "api/*" \
  --profile villaai

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*" \
  --profile villaai
```

### Deployment Scripts

Create a convenience script (`scripts/deploy.sh`):

```bash
#!/bin/bash
set -e

PROFILE="villaai"
BUCKET="docs.gt.villamarket.ai"
DISTRIBUTION_ID="${CF_DIST_ID:-}"

echo "Building site..."
npm run build

echo "Deploying to S3..."
aws s3 sync build/ "s3://${BUCKET}/" \
  --delete \
  --cache-control "public, max-age=3600" \
  --exclude "*.html" \
  --exclude "sitemap.xml" \
  --exclude "llm.txt" \
  --exclude "llm-full.txt" \
  --profile "$PROFILE"

aws s3 sync build/ "s3://${BUCKET}/" \
  --cache-control "public, max-age=300" \
  --exclude "*" \
  --include "*.html" \
  --include "sitemap.xml" \
  --include "llm.txt" \
  --include "llm-full.txt" \
  --include "api/*" \
  --profile "$PROFILE"

if [ -n "$DISTRIBUTION_ID" ]; then
  echo "Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --profile "$PROFILE"
fi

echo "Deployment complete!"
echo "Site URL: https://docs.gt.villamarket.ai"
```

Make it executable:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

---

## Caching Strategy

The deployment uses different cache controls for different file types:

| File Type | Cache Control | Rationale |
|-----------|--------------|-----------|
| Static assets (JS, CSS, images) | `max-age=3600` (1 hour) | Content-hashed filenames, safe to cache |
| HTML files | `max-age=300` (5 min) | Frequent updates, short cache |
| `sitemap.xml`, `llm.txt` | `max-age=300` (5 min) | Dynamic content |

---

## Troubleshooting

### CloudFront Returns 403 Forbidden

Ensure the S3 bucket policy allows public read access and the CloudFront origin is set to the **S3 website endpoint** (not the REST endpoint).

### Trailing Slash Redirect Issues

Verify the CloudFront Function is attached to the distribution's **Viewer Request** event.

### Changes Not Appearing

1. Check S3 for updated files
2. Verify CloudFront invalidation completed
3. Clear browser cache or use incognito mode

### SSL Certificate Issues

If using a custom domain, ensure the SSL certificate in ACM covers `docs.gt.villamarket.ai` and is in the `us-east-1` region (required for CloudFront).

---

## Cost Optimization

| Service | Cost Driver | Optimization |
|---------|-------------|--------------|
| S3 | Storage, requests | Enable compression, use lifecycle policies |
| CloudFront | Data transfer, requests | Optimize assets, use appropriate cache TTLs |
| Route 53 | Hosted zone, queries | Use alias records |

Typical monthly cost for low-traffic documentation: **$5-15 USD**

---

## Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Functions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html)
- [Docusaurus Deployment](https://docusaurus.io/docs/deployment)
