#!/usr/bin/env node
/**
 * Check external links in documentation for reachability.
 *
 * Usage:
 *   node scripts/check-external-links.js          # Check all external links
 *   node scripts/check-external-links.js --quiet   # Only show failures
 *
 * Exit code 0 = all reachable, 1 = failures found.
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const DOCS_DIR = path.resolve(__dirname, '..', 'docs');
const TIMEOUT_MS = 10000;
const CONCURRENCY = 5;
const quiet = process.argv.includes('--quiet');

// Domains that block automated requests (403) but are valid for humans
const BOT_BLOCKED_DOMAINS = [
  'medium.com',
  'claude.ai',
];

function collectFiles(dir) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...collectFiles(full));
    } else if (entry.name.endsWith('.md') || entry.name.endsWith('.mdx')) {
      results.push(full);
    }
  }
  return results;
}

function extractExternalLinks(files) {
  const linkPattern = /\[([^\]]*)\]\((https?:\/\/[^)]+)\)/g;
  const urlMap = new Map(); // url -> [files]

  for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');
    const rel = path.relative(DOCS_DIR, file);
    let match;
    const pat = new RegExp(linkPattern.source, 'g');
    while ((match = pat.exec(content)) !== null) {
      const url = match[2];
      if (!urlMap.has(url)) urlMap.set(url, []);
      urlMap.get(url).push(rel);
    }
  }
  return urlMap;
}

function checkUrl(url) {
  return new Promise((resolve) => {
    const mod = url.startsWith('https') ? https : http;
    const req = mod.get(url, { timeout: TIMEOUT_MS, headers: { 'User-Agent': 'gastown-docs-link-checker/1.0' } }, (res) => {
      // Follow redirects
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        resolve({ url, status: res.statusCode, ok: true, redirect: res.headers.location });
      } else {
        resolve({ url, status: res.statusCode, ok: res.statusCode >= 200 && res.statusCode < 400 });
      }
      res.resume(); // consume response
    });
    req.on('timeout', () => {
      req.destroy();
      resolve({ url, status: 'TIMEOUT', ok: false });
    });
    req.on('error', (err) => {
      resolve({ url, status: err.code || err.message, ok: false });
    });
  });
}

async function runBatch(urls, concurrency) {
  const results = [];
  const queue = [...urls];

  async function worker() {
    while (queue.length > 0) {
      const url = queue.shift();
      const result = await checkUrl(url);
      results.push(result);
    }
  }

  const workers = Array.from({ length: Math.min(concurrency, urls.length) }, () => worker());
  await Promise.all(workers);
  return results;
}

async function main() {
  console.log('Checking external links...');

  const files = collectFiles(DOCS_DIR);
  const urlMap = extractExternalLinks(files);
  const uniqueUrls = [...urlMap.keys()];

  console.log(`  Found ${uniqueUrls.length} unique external URLs across ${files.length} files`);
  console.log('');

  const results = await runBatch(uniqueUrls, CONCURRENCY);

  let failures = 0;
  let skipped = 0;
  for (const r of results) {
    const isBotBlocked = !r.ok && r.status === 403 &&
      BOT_BLOCKED_DOMAINS.some(d => r.url.includes(d));

    if (r.ok) {
      if (!quiet) {
        const suffix = r.redirect ? ` → ${r.redirect}` : '';
        console.log(`  OK   [${r.status}] ${r.url}${suffix}`);
      }
    } else if (isBotBlocked) {
      skipped++;
      if (!quiet) {
        console.log(`  SKIP [${r.status}] ${r.url} (bot-blocked domain, assumed valid)`);
      }
    } else {
      const sources = urlMap.get(r.url).join(', ');
      console.log(`  FAIL [${r.status}] ${r.url}`);
      console.log(`        referenced in: ${sources}`);
      failures++;
    }
  }

  console.log('');
  const skipMsg = skipped > 0 ? `, ${skipped} skipped (bot-blocked)` : '';
  if (failures > 0) {
    console.log(`FAILED: ${failures} broken link(s) out of ${uniqueUrls.length} checked${skipMsg}`);
    process.exit(1);
  } else {
    console.log(`PASSED: all ${uniqueUrls.length} external links OK${skipMsg}`);
    process.exit(0);
  }
}

main();
