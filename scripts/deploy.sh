#!/usr/bin/env bash
set -euo pipefail

# Gas Town Documentation — Deploy to AWS (S3 + CloudFront)
#
# Prerequisites:
#   - AWS CLI configured with appropriate credentials
#   - S3 bucket created: docs.gt.villamarket.ai
#   - CloudFront distribution configured
#   - CF_DIST_ID environment variable set
#
# Usage:
#   CF_DIST_ID=E1234567890 ./scripts/deploy.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
S3_BUCKET="docs.gt.villamarket.ai"
CF_FUNCTION_NAME="gastown-docs-url-rewrite"

if [ -z "${CF_DIST_ID:-}" ]; then
  echo "Error: CF_DIST_ID environment variable not set"
  echo "Usage: CF_DIST_ID=<distribution-id> $0"
  exit 1
fi

echo "=== Gas Town Docs Deploy ==="
echo "Bucket:       s3://${S3_BUCKET}"
echo "Distribution: ${CF_DIST_ID}"
echo ""

# Build
echo "--- Building documentation ---"
cd "$PROJECT_DIR"
npm run build

# Sync to S3
echo ""
echo "--- Syncing to S3 ---"
aws s3 sync build/ "s3://${S3_BUCKET}" \
  --delete \
  --cache-control "public, max-age=3600" \
  --exclude "*.html" \
  --exclude "sitemap.xml" \
  --exclude "llm.txt" \
  --exclude "llm-full.txt"

# HTML and dynamic files with shorter cache
aws s3 sync build/ "s3://${S3_BUCKET}" \
  --cache-control "public, max-age=300" \
  --exclude "*" \
  --include "*.html" \
  --include "sitemap.xml" \
  --include "llm.txt" \
  --include "llm-full.txt" \
  --include "api/*"

# Ensure CloudFront Function exists for URL rewriting
# This handles: /docs -> 301 /docs/ and /docs/ -> /docs/index.html
echo ""
echo "--- Ensuring CloudFront Function ---"
CF_FUNC_FILE="$PROJECT_DIR/cloudfront/url-rewrite.js"

if aws cloudfront describe-function --name "$CF_FUNCTION_NAME" --output text >/dev/null 2>&1; then
  echo "Updating existing CloudFront Function: $CF_FUNCTION_NAME"
  ETAG=$(aws cloudfront describe-function --name "$CF_FUNCTION_NAME" --query 'ETag' --output text)
  aws cloudfront update-function \
    --name "$CF_FUNCTION_NAME" \
    --function-config '{"Comment":"URL rewrite for Docusaurus trailing slash","Runtime":"cloudfront-js-2.0"}' \
    --function-code "fileb://${CF_FUNC_FILE}" \
    --if-match "$ETAG" \
    --output text
  ETAG=$(aws cloudfront describe-function --name "$CF_FUNCTION_NAME" --query 'ETag' --output text)
  aws cloudfront publish-function --name "$CF_FUNCTION_NAME" --if-match "$ETAG" --output text
  echo "CloudFront Function updated and published"
else
  echo "Creating CloudFront Function: $CF_FUNCTION_NAME"
  aws cloudfront create-function \
    --name "$CF_FUNCTION_NAME" \
    --function-config '{"Comment":"URL rewrite for Docusaurus trailing slash","Runtime":"cloudfront-js-2.0"}' \
    --function-code "fileb://${CF_FUNC_FILE}" \
    --output text
  ETAG=$(aws cloudfront describe-function --name "$CF_FUNCTION_NAME" --query 'ETag' --output text)
  aws cloudfront publish-function --name "$CF_FUNCTION_NAME" --if-match "$ETAG" --output text
  echo "CloudFront Function created and published"
  echo ""
  echo "NOTE: You must manually associate this function with the distribution."
  echo "  Distribution: ${CF_DIST_ID}"
  echo "  Function:     ${CF_FUNCTION_NAME}"
  echo "  Event type:   viewer-request"
  echo "  Run: aws cloudfront get-distribution-config --id ${CF_DIST_ID}"
  echo "  Then update the default cache behavior to include the function association."
fi

# Invalidate CloudFront cache
echo ""
echo "--- Invalidating CloudFront cache ---"
aws cloudfront create-invalidation \
  --distribution-id "$CF_DIST_ID" \
  --paths "/*" \
  --output text

echo ""
echo "=== Deploy complete ==="
echo "Site: https://docs.gt.villamarket.ai"
