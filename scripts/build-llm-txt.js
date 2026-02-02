#!/usr/bin/env node
/**
 * Build AI/LLM-optimized access files:
 *   - static/llm.txt       — Concatenated summary of all docs
 *   - static/llm-full.txt  — Full concatenation of all docs
 *   - static/api/docs.json — Structured index of all pages
 *
 * Run as part of the build pipeline (pre-build step).
 */

const fs = require('fs');
const path = require('path');

const DOCS_DIR = path.resolve(__dirname, '..', 'docs');
const STATIC_DIR = path.resolve(__dirname, '..', 'static');

// Section ordering for structured output
const SECTION_ORDER = [
  '',                // root (index.md)
  'getting-started',
  'architecture',
  'cli-reference',
  'agents',
  'concepts',
  'workflows',
  'operations',
  'guides',
];

function stripFrontMatter(content) {
  if (content.startsWith('---')) {
    const end = content.indexOf('---', 3);
    if (end !== -1) {
      return content.substring(end + 3).trim();
    }
  }
  return content;
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
    }
  }
  return meta;
}

function stripImports(content) {
  // Remove Docusaurus component imports
  return content.replace(/^import\s+.*from\s+['"].*['"];?\s*$/gm, '').trim();
}

function collectDocs(dir, baseDir, docs) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      if (file === 'assets' || file === 'stylesheets') continue;
      collectDocs(fullPath, baseDir, docs);
    } else if (file.endsWith('.md')) {
      const relPath = path.relative(baseDir, fullPath);
      const content = fs.readFileSync(fullPath, 'utf8');
      const meta = extractFrontMatter(content);
      const body = stripImports(stripFrontMatter(content));
      const section = path.dirname(relPath) === '.' ? '' : path.dirname(relPath);

      docs.push({
        path: relPath,
        section,
        title: meta.title || file.replace('.md', ''),
        description: meta.description || '',
        sidebar_position: meta.sidebar_position ?? 99,
        body,
        url: `/docs/${relPath.replace('.md', '').replace(/\/index$/, '')}`,
      });
    }
  }
}

function buildLlmTxt(docs) {
  const lines = [];
  lines.push('# Gas Town Documentation');
  lines.push('# https://docs.gt.villamarket.ai');
  lines.push('# Multi-agent orchestration for AI coding agents');
  lines.push('');
  lines.push('## Table of Contents');
  lines.push('');

  // Group by section
  const grouped = {};
  for (const doc of docs) {
    const key = doc.section || '_root';
    if (!grouped[key]) grouped[key] = [];
    grouped[key].push(doc);
  }

  // Sort within sections
  for (const key of Object.keys(grouped)) {
    grouped[key].sort((a, b) => a.sidebar_position - b.sidebar_position);
  }

  // TOC
  for (const section of SECTION_ORDER) {
    const key = section || '_root';
    const sectionDocs = grouped[key];
    if (!sectionDocs) continue;
    const sectionTitle = section
      ? section.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
      : 'Home';
    lines.push(`### ${sectionTitle}`);
    for (const doc of sectionDocs) {
      lines.push(`- ${doc.title}: ${doc.url}`);
    }
    lines.push('');
  }

  lines.push('---');
  lines.push('');

  // Summary content (first 3 lines of each doc body)
  for (const section of SECTION_ORDER) {
    const key = section || '_root';
    const sectionDocs = grouped[key];
    if (!sectionDocs) continue;

    for (const doc of sectionDocs) {
      lines.push(`## ${doc.title}`);
      lines.push(`> ${doc.url}`);
      lines.push('');
      if (doc.description) {
        lines.push(doc.description);
        lines.push('');
      }
      // First meaningful paragraph
      const paragraphs = doc.body.split('\n\n').filter(p =>
        p.trim() && !p.startsWith('#') && !p.startsWith('|') && !p.startsWith('```')
      );
      if (paragraphs.length > 0) {
        lines.push(paragraphs[0].trim());
        lines.push('');
      }
      lines.push('---');
      lines.push('');
    }
  }

  return lines.join('\n');
}

function buildLlmFullTxt(docs) {
  const lines = [];
  lines.push('# Gas Town Documentation — Full Content');
  lines.push('# https://docs.gt.villamarket.ai');
  lines.push('# Multi-agent orchestration for AI coding agents');
  lines.push('');

  // Group by section
  const grouped = {};
  for (const doc of docs) {
    const key = doc.section || '_root';
    if (!grouped[key]) grouped[key] = [];
    grouped[key].push(doc);
  }

  for (const key of Object.keys(grouped)) {
    grouped[key].sort((a, b) => a.sidebar_position - b.sidebar_position);
  }

  for (const section of SECTION_ORDER) {
    const key = section || '_root';
    const sectionDocs = grouped[key];
    if (!sectionDocs) continue;

    for (const doc of sectionDocs) {
      lines.push('');
      lines.push(`${'='.repeat(72)}`);
      lines.push(`# ${doc.title}`);
      lines.push(`# URL: ${doc.url}`);
      lines.push(`${'='.repeat(72)}`);
      lines.push('');
      lines.push(doc.body);
      lines.push('');
    }
  }

  return lines.join('\n');
}

function buildDocsJson(docs) {
  const grouped = {};
  for (const doc of docs) {
    const key = doc.section || '_root';
    if (!grouped[key]) grouped[key] = [];
    grouped[key].push(doc);
  }

  for (const key of Object.keys(grouped)) {
    grouped[key].sort((a, b) => a.sidebar_position - b.sidebar_position);
  }

  const index = {
    name: 'Gas Town Documentation',
    url: 'https://docs.gt.villamarket.ai',
    description: 'Multi-agent orchestration for AI coding agents',
    generated: new Date().toISOString(),
    sections: SECTION_ORDER.filter(s => s !== '').map(section => {
      const sectionDocs = grouped[section] || [];
      return {
        id: section,
        title: section.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
        pages: sectionDocs.map(doc => ({
          title: doc.title,
          path: doc.url,
          description: doc.description,
        })),
      };
    }),
    pages: docs.map(doc => ({
      title: doc.title,
      path: doc.url,
      section: doc.section || 'root',
      description: doc.description,
    })),
  };

  return JSON.stringify(index, null, 2);
}

// Main
console.log('Building AI/LLM access files...');

const docs = [];
collectDocs(DOCS_DIR, DOCS_DIR, docs);
console.log(`  Found ${docs.length} documentation files`);

// Ensure output directories exist
fs.mkdirSync(path.join(STATIC_DIR, 'api'), { recursive: true });

// Build llm.txt
const llmTxt = buildLlmTxt(docs);
fs.writeFileSync(path.join(STATIC_DIR, 'llm.txt'), llmTxt, 'utf8');
console.log(`  Generated static/llm.txt (${(llmTxt.length / 1024).toFixed(1)} KB)`);

// Build llm-full.txt
const llmFull = buildLlmFullTxt(docs);
fs.writeFileSync(path.join(STATIC_DIR, 'llm-full.txt'), llmFull, 'utf8');
console.log(`  Generated static/llm-full.txt (${(llmFull.length / 1024).toFixed(1)} KB)`);

// Build docs.json
const docsJson = buildDocsJson(docs);
fs.writeFileSync(path.join(STATIC_DIR, 'api', 'docs.json'), docsJson, 'utf8');
console.log(`  Generated static/api/docs.json (${(docsJson.length / 1024).toFixed(1)} KB)`);

console.log('Done!');
