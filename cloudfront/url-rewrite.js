// CloudFront Function: URL Rewrite for Docusaurus (trailingSlash: true)
//
// Handles two cases that S3 REST API cannot resolve:
// 1. /docs/ → /docs/index.html  (directory index resolution)
// 2. /docs  → 301 to /docs/     (trailing slash redirect)
//
// Deploy: associated with CloudFront distribution as a viewer-request function.
// See scripts/deploy.sh for automated deployment.

function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // If URI ends with '/', append index.html for S3 resolution
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    // If URI has no file extension, redirect to trailing slash version
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
