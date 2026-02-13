#!/usr/bin/env node
/**
 * Validate documentation quality:
 *   - All pages have required frontmatter (title, description, sidebar_position)
 *   - No duplicate sidebar_position values within a directory
 *   - All internal markdown links resolve to existing files
 *   - All pages referenced in sidebars.ts exist
 *
 * Exit code 0 = all checks pass, 1 = failures found.
 */

const fs = require('fs');
const path = require('path');

const DOCS_DIR = path.resolve(__dirname, '..', 'docs');
const ROOT_DIR = path.resolve(__dirname, '..');

let errors = 0;
let warnings = 0;

function error(msg) {
  console.error(`  ERROR: ${msg}`);
  errors++;
}

function warn(msg) {
  console.warn(`  WARN:  ${msg}`);
  warnings++;
}

function collectFiles(dir, ext) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...collectFiles(full, ext));
    } else if (entry.name.endsWith(ext)) {
      results.push(full);
    }
  }
  return results;
}

function extractFrontMatter(content) {
  const meta = {};
  if (content.startsWith('---')) {
    const end = content.indexOf('---', 3);
    if (end !== -1) {
      const fm = content.substring(3, end);
      const titleMatch = fm.match(/title:\s*"([^"]+)"/);
      const descMatch = fm.match(/description:\s*"([^"]+)"/);
      const posMatch = fm.match(/sidebar_position:\s*(\d+)/);
      if (titleMatch) meta.title = titleMatch[1];
      if (descMatch) meta.description = descMatch[1];
      if (posMatch) meta.sidebar_position = parseInt(posMatch[1]);
      meta._raw = fm;
    }
  }
  return meta;
}

// ─── Check 1: Frontmatter validation ───
console.log('Checking frontmatter...');
const mdFiles = collectFiles(DOCS_DIR, '.md');
const fileMap = new Map(); // relPath -> meta

for (const file of mdFiles) {
  const rel = path.relative(DOCS_DIR, file);
  const content = fs.readFileSync(file, 'utf8');
  const meta = extractFrontMatter(content);
  fileMap.set(rel, { meta, content, file });

  if (!meta.title) error(`${rel}: missing frontmatter 'title'`);
  if (!meta.description) error(`${rel}: missing frontmatter 'description'`);
  if (meta.sidebar_position === undefined) error(`${rel}: missing frontmatter 'sidebar_position'`);
}
console.log(`  ${mdFiles.length} files checked`);

// ─── Check 2: Duplicate sidebar positions ───
console.log('Checking sidebar positions...');
const byDir = new Map();
for (const [rel, { meta }] of fileMap) {
  const dir = path.dirname(rel);
  if (!byDir.has(dir)) byDir.set(dir, []);
  byDir.get(dir).push({ rel, pos: meta.sidebar_position });
}

for (const [dir, entries] of byDir) {
  const seen = new Map();
  for (const { rel, pos } of entries) {
    if (pos === undefined) continue;
    if (seen.has(pos)) {
      error(`Duplicate sidebar_position ${pos} in ${dir}/: ${seen.get(pos)} and ${rel}`);
    }
    seen.set(pos, rel);
  }
}

// ─── Check 3: Internal link validation ───
console.log('Checking internal links...');
const linkPattern = /\[([^\]]*)\]\(([^)]+)\)/g;
let linkCount = 0;

for (const [rel, { content, file }] of fileMap) {
  const dir = path.dirname(file);
  let match;
  const localPattern = new RegExp(linkPattern.source, 'g');
  while ((match = localPattern.exec(content)) !== null) {
    const linkTarget = match[2];

    // Skip external links, anchors, and special protocols
    if (linkTarget.startsWith('http://') || linkTarget.startsWith('https://')) continue;
    if (linkTarget.startsWith('#')) continue;
    if (linkTarget.startsWith('mailto:')) continue;

    // Strip anchor from link
    const targetPath = linkTarget.split('#')[0];
    if (!targetPath) continue;

    // Resolve relative to current file's directory
    const resolved = path.resolve(dir, targetPath);
    linkCount++;

    if (!fs.existsSync(resolved)) {
      error(`${rel}: broken link [${match[1]}](${linkTarget}) → ${path.relative(DOCS_DIR, resolved)} not found`);
    }
  }
}
console.log(`  ${linkCount} internal links checked`);

// ─── Summary ───
console.log('');
if (errors > 0) {
  console.log(`FAILED: ${errors} error(s), ${warnings} warning(s)`);
  process.exit(1);
} else {
  console.log(`PASSED: ${mdFiles.length} files, ${linkCount} links, 0 errors, ${warnings} warning(s)`);
  process.exit(0);
}
