#!/usr/bin/env node
/**
 * Migrate MkDocs Material markdown files to Docusaurus format.
 *
 * Conversions:
 *   - Add front matter (title, sidebar_position, description)
 *   - !!! type "Title" -> :::type[Title]  (admonitions)
 *   - ??? type "Title" -> <details> blocks (collapsible)
 *   - === "Tab Title" -> <Tabs>/<TabItem> components
 *   - Preserve mermaid fences (native in Docusaurus with plugin)
 */

const fs = require('fs');
const path = require('path');

const DOCS_DIR = path.resolve(__dirname, '..', 'docs');

// Sidebar position mapping derived from mkdocs.yml nav order
const sidebarPositions = {
  'index.md': 0,
  // Getting Started
  'getting-started/index.md': 0,
  'getting-started/installation.md': 1,
  'getting-started/quickstart.md': 2,
  'getting-started/first-convoy.md': 3,
  // Architecture
  'architecture/index.md': 0,
  'architecture/overview.md': 1,
  'architecture/agent-hierarchy.md': 2,
  'architecture/work-distribution.md': 3,
  'architecture/design-principles.md': 4,
  // CLI Reference
  'cli-reference/index.md': 0,
  'cli-reference/workspace.md': 1,
  'cli-reference/agents.md': 2,
  'cli-reference/work.md': 3,
  'cli-reference/convoys.md': 4,
  'cli-reference/communication.md': 5,
  'cli-reference/merge-queue.md': 6,
  'cli-reference/rigs.md': 7,
  'cli-reference/sessions.md': 8,
  'cli-reference/diagnostics.md': 9,
  'cli-reference/configuration.md': 10,
  // Agents
  'agents/index.md': 0,
  'agents/mayor.md': 1,
  'agents/deacon.md': 2,
  'agents/witness.md': 3,
  'agents/refinery.md': 4,
  'agents/polecats.md': 5,
  'agents/dogs.md': 6,
  'agents/crew.md': 7,
  'agents/boot.md': 8,
  // Concepts
  'concepts/index.md': 0,
  'concepts/beads.md': 1,
  'concepts/hooks.md': 2,
  'concepts/convoys.md': 3,
  'concepts/molecules.md': 4,
  'concepts/gates.md': 5,
  'concepts/rigs.md': 6,
  // Workflows
  'workflows/index.md': 0,
  'workflows/mayor-workflow.md': 1,
  'workflows/minimal-mode.md': 2,
  'workflows/manual-convoy.md': 3,
  'workflows/formula-workflow.md': 4,
  'workflows/code-review.md': 5,
  // Operations
  'operations/index.md': 0,
  'operations/lifecycle.md': 1,
  'operations/monitoring.md': 2,
  'operations/escalations.md': 3,
  'operations/troubleshooting.md': 4,
  'operations/plugins.md': 5,
  // Guides
  'guides/index.md': 0,
  'guides/usage-guide.md': 1,
  'guides/eight-stages.md': 2,
  'guides/multi-runtime.md': 3,
  'guides/cost-management.md': 4,
  'guides/philosophy.md': 5,
};

function extractTitle(content) {
  // Get the first H1 heading
  const match = content.match(/^#\s+(.+)$/m);
  return match ? match[1].trim() : 'Untitled';
}

function extractDescription(content) {
  // Get first non-empty paragraph after the title
  const lines = content.split('\n');
  let foundTitle = false;
  let desc = '';
  for (const line of lines) {
    if (line.startsWith('# ')) {
      foundTitle = true;
      continue;
    }
    if (foundTitle && line.trim() === '') continue;
    if (foundTitle && line.trim() === '---') continue;
    if (foundTitle && line.trim() && !line.startsWith('#') && !line.startsWith('|') && !line.startsWith('```')) {
      desc = line.trim()
        .replace(/\*\*/g, '')
        .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
        .replace(/`([^`]+)`/g, '$1');
      break;
    }
  }
  // Truncate to ~160 chars
  if (desc.length > 160) {
    desc = desc.substring(0, 157) + '...';
  }
  return desc;
}

function convertAdmonitions(content) {
  // Convert MkDocs admonitions: !!! type "Title" to :::type[Title]
  // Handle multi-line indented content

  const lines = content.split('\n');
  const result = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];

    // Match !!! type "Title" or !!! type
    const admonitionMatch = line.match(/^(!{3})\s+(\w+)\s*(?:"([^"]*)")?$/);
    // Match ??? type "Title" (collapsible)
    const detailsMatch = line.match(/^(\?{3})\s+(\w+)\s*(?:"([^"]*)")?$/);

    if (admonitionMatch) {
      const type = admonitionMatch[2];
      const title = admonitionMatch[3];
      const titlePart = title ? `[${title}]` : '';
      result.push(`:::${type}${titlePart}`);
      result.push('');

      // Collect indented content
      i++;
      while (i < lines.length && (lines[i].startsWith('    ') || lines[i].trim() === '')) {
        if (lines[i].trim() === '' && i + 1 < lines.length && !lines[i + 1].startsWith('    ') && lines[i + 1].trim() !== '') {
          break;
        }
        result.push(lines[i].replace(/^    /, ''));
        i++;
      }
      result.push('');
      result.push(':::');
      continue;
    }

    if (detailsMatch) {
      const type = detailsMatch[2];
      const title = detailsMatch[3] || type.charAt(0).toUpperCase() + type.slice(1);
      result.push(`<details>`);
      result.push(`<summary>${title}</summary>`);
      result.push('');

      // Collect indented content
      i++;
      while (i < lines.length && (lines[i].startsWith('    ') || lines[i].trim() === '')) {
        if (lines[i].trim() === '' && i + 1 < lines.length && !lines[i + 1].startsWith('    ') && lines[i + 1].trim() !== '') {
          break;
        }
        result.push(lines[i].replace(/^    /, ''));
        i++;
      }
      result.push('');
      result.push('</details>');
      continue;
    }

    result.push(line);
    i++;
  }

  return result.join('\n');
}

function convertTabs(content) {
  // Convert pymdownx.tabbed === "Title" to Docusaurus Tabs/TabItem
  const lines = content.split('\n');
  const result = [];
  let i = 0;
  let inTabs = false;
  let tabCount = 0;
  let needsImport = false;

  while (i < lines.length) {
    const line = lines[i];
    const tabMatch = line.match(/^===\s+"([^"]+)"$/);

    if (tabMatch) {
      const tabLabel = tabMatch[1];

      if (!inTabs) {
        // Start a new Tabs group
        inTabs = true;
        tabCount = 0;
        needsImport = true;
        result.push('<Tabs>');
      } else {
        // Close previous TabItem
        result.push('</TabItem>');
      }

      result.push(`<TabItem value="${tabLabel.toLowerCase().replace(/[^a-z0-9]+/g, '-')}" label="${tabLabel}">`);
      tabCount++;

      // Collect indented content
      i++;
      while (i < lines.length) {
        const nextLine = lines[i];
        // Check if next non-empty line is another tab or non-indented
        if (nextLine.match(/^===\s+"[^"]+"$/)) {
          break; // Another tab, don't increment i
        }
        if (nextLine.startsWith('    ') || nextLine.trim() === '') {
          result.push(nextLine.replace(/^    /, ''));
          i++;
        } else {
          break;
        }
      }
      continue;
    }

    if (inTabs && !line.match(/^===/) && !line.startsWith('    ') && line.trim() !== '') {
      // End of tabs section
      result.push('</TabItem>');
      result.push('</Tabs>');
      inTabs = false;
    }

    result.push(line);
    i++;
  }

  // Close any unclosed tabs
  if (inTabs) {
    result.push('</TabItem>');
    result.push('</Tabs>');
  }

  // Add import at top if needed
  if (needsImport) {
    return `import Tabs from '@theme/Tabs';\nimport TabItem from '@theme/TabItem';\n\n${result.join('\n')}`;
  }

  return result.join('\n');
}

function addFrontMatter(content, relPath) {
  const title = extractTitle(content);
  const description = extractDescription(content);
  const position = sidebarPositions[relPath];

  let frontMatter = '---\n';
  frontMatter += `title: "${title.replace(/"/g, '\\"')}"\n`;
  if (position !== undefined) {
    frontMatter += `sidebar_position: ${position}\n`;
  }
  if (description) {
    frontMatter += `description: "${description.replace(/"/g, '\\"')}"\n`;
  }
  frontMatter += '---\n\n';

  return frontMatter + content;
}

function processFile(filePath, relPath) {
  let content = fs.readFileSync(filePath, 'utf8');

  // Convert admonitions
  content = convertAdmonitions(content);

  // Convert tabs
  content = convertTabs(content);

  // Add front matter
  content = addFrontMatter(content, relPath);

  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`  Migrated: ${relPath}`);
}

function walkDir(dir, baseDir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      // Skip assets and stylesheets
      if (file === 'assets' || file === 'stylesheets') continue;
      walkDir(fullPath, baseDir);
    } else if (file.endsWith('.md')) {
      const relPath = path.relative(baseDir, fullPath);
      processFile(fullPath, relPath);
    }
  }
}

console.log('Migrating MkDocs files to Docusaurus format...\n');
walkDir(DOCS_DIR, DOCS_DIR);
console.log('\nMigration complete!');
