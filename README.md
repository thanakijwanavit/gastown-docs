# Gas Town Documentation

Comprehensive documentation for Gas Town - the multi-agent orchestration system for AI coding agents.

## Overview

This is a Docusaurus-based documentation site deployed to AWS (S3 + CloudFront) at:
**https://docs.gt.villamarket.ai**

## Documentation Structure

- **Getting Started** — Installation, quick start, and first convoy walkthrough
- **Architecture** — System design, agent hierarchy, and work distribution
- **CLI Reference** — Complete `gt` command documentation
- **Agents** — Detailed guides for each agent role (Mayor, Polecats, Refinery, etc.)
- **Core Concepts** — Beads, Hooks, Convoys, Molecules, GUPP, and more
- **Workflows** — Common workflow patterns and best practices
- **Operations** — Running, monitoring, and troubleshooting
- **Guides** — Usage guide, philosophy, cost management, AWS deployment

## Local Development

```bash
# Install dependencies
npm ci

# Start development server
npm run start

# Build for production
npm run build

# Serve built site locally
npm run serve
```

## Deployment

### Automated (GitHub Actions)

Pushes to `master` branch automatically deploy via GitHub Actions:
- Build the site
- Sync to S3 bucket (`docs.gt.villamarket.ai`)
- Update CloudFront function
- Invalidate CloudFront cache

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `CF_DIST_ID`

### Manual (AWS villaai profile)

```bash
# Configure AWS profile
aws configure --profile villaai

# Deploy
aws s3 sync build/ s3://docs.gt.villamarket.ai/ --delete --profile villaai
aws cloudfront create-invalidation --distribution-id $CF_DIST_ID --paths "/*" --profile villaai
```

See [AWS Deployment Guide](docs/guides/aws-deployment.md) for full details.

## Sources

This documentation is based on:
- Gas Town source code and CLI help
- Steve Yegge's Medium articles on Gas Town
- Community usage patterns and best practices

## License

Copyright 2025 Villa Market AI. Built with Docusaurus.
