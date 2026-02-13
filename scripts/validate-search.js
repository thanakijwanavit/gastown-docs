#!/usr/bin/env node
/**
 * Validate search index quality after build:
 *   - search-index.json exists and is valid JSON
 *   - Index contains expected number of documents
 *   - Key Gas Town terms are present in the inverted index
 *   - All document URLs are well-formed
 *
 * Requires: npm run build (to generate build/search-index.json)
 * Exit code 0 = all checks pass, 1 = failures found.
 */

const fs = require('fs');
const path = require('path');

const BUILD_DIR = path.resolve(__dirname, '..', 'build');
const INDEX_PATH = path.join(BUILD_DIR, 'search-index.json');

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

// ─── Check 1: Search index exists ───
console.log('Checking search index...');
if (!fs.existsSync(INDEX_PATH)) {
  console.error('FAILED: build/search-index.json not found. Run `npm run build` first.');
  process.exit(1);
}

let index;
try {
  index = JSON.parse(fs.readFileSync(INDEX_PATH, 'utf8'));
} catch (e) {
  console.error(`FAILED: search-index.json is not valid JSON: ${e.message}`);
  process.exit(1);
}

if (!Array.isArray(index) || index.length === 0) {
  console.error('FAILED: search-index.json is empty or not an array');
  process.exit(1);
}
console.log(`  ${index.length} index section(s) loaded`);

// ─── Check 2: Document count ───
console.log('Checking document coverage...');
let totalDocs = 0;
for (const section of index) {
  if (section.documents) {
    totalDocs += section.documents.length;
  }
}
// We expect at least 70 unique pages (75 docs + blog + homepage)
const MIN_DOCS = 70;
if (totalDocs < MIN_DOCS) {
  error(`Only ${totalDocs} documents indexed (expected >= ${MIN_DOCS})`);
} else {
  console.log(`  ${totalDocs} documents indexed`);
}

// ─── Check 3: Key terms in inverted index ───
console.log('Checking key terms...');

// Collect all terms from all sections' inverted indexes
const allTerms = new Set();
for (const section of index) {
  if (section.index?.invertedIndex) {
    for (const entry of section.index.invertedIndex) {
      if (Array.isArray(entry) && entry.length > 0) {
        allTerms.add(entry[0]);
      }
    }
  }
}
console.log(`  ${allTerms.size} unique terms in index`);

// Key Gas Town terms (using lunr stemmed forms where needed)
const requiredTerms = [
  { term: 'polecat', label: 'polecat (agent type)' },
  { term: 'molecul', label: 'molecule (workflow, stemmed)' },
  { term: 'bead', label: 'bead (issue tracking)' },
  { term: 'convoy', label: 'convoy (work batch)' },
  { term: 'gupp', label: 'GUPP (propulsion principle)' },
  { term: 'mayor', label: 'Mayor (coordinator agent)' },
  { term: 'deacon', label: 'Deacon (watchdog agent)' },
  { term: 'crew', label: 'crew (human workspaces)' },
  { term: 'hook', label: 'hook (work assignment)' },
  { term: 'refin', label: 'refinery (merge queue, stemmed)' },
];

let termHits = 0;
for (const { term, label } of requiredTerms) {
  if (allTerms.has(term)) {
    termHits++;
  } else {
    error(`Key term "${term}" (${label}) not found in search index`);
  }
}
console.log(`  ${termHits}/${requiredTerms.length} key terms found`);

// ─── Check 4: Document URL validation ───
console.log('Checking document URLs...');
let urlCount = 0;
let badUrls = 0;
for (const section of index) {
  if (!section.documents) continue;
  for (const doc of section.documents) {
    urlCount++;
    if (!doc.u || typeof doc.u !== 'string') {
      error(`Document ${doc.i} has invalid URL: ${JSON.stringify(doc.u)}`);
      badUrls++;
    } else if (!doc.u.startsWith('/')) {
      warn(`Document "${doc.t}" has non-absolute URL: ${doc.u}`);
    }
  }
}
console.log(`  ${urlCount} document URLs checked`);

// ─── Check 5: No empty sections ───
console.log('Checking section health...');
let emptySections = 0;
for (let i = 0; i < index.length; i++) {
  const section = index[i];
  const docCount = section.documents?.length || 0;
  const termCount = section.index?.invertedIndex?.length || 0;
  if (docCount === 0 && termCount === 0) {
    emptySections++;
  }
}
if (emptySections > 1) {
  warn(`${emptySections} empty index sections (expected at most 1)`);
}

// ─── Summary ───
console.log('');
if (errors > 0) {
  console.log(`FAILED: ${errors} error(s), ${warnings} warning(s)`);
  process.exit(1);
} else {
  console.log(`PASSED: ${totalDocs} docs, ${allTerms.size} terms, ${termHits}/${requiredTerms.length} key terms, ${errors} errors, ${warnings} warning(s)`);
  process.exit(0);
}
