#!/bin/bash
# Test script for Gas Town documentation
# Validates documentation quality and catches common issues

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🧪 Running Gas Town Documentation Tests"
echo "========================================"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to report test results
pass_test() {
    echo "✓ $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    echo "✗ $1"
    echo "  Error: $2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test 1: Build succeeds
echo "Test 1: Documentation builds without errors..."
if npm run build > /dev/null 2>&1; then
    pass_test "Documentation builds successfully"
else
    fail_test "Documentation build failed" "Run 'npm run build' to see errors"
fi

# Test 2: Check for broken internal links
echo ""
echo "Test 2: Checking for broken internal links..."
cd "$ROOT_DIR/docs"
BROKEN_LINKS=0

# Find all markdown files and check internal links
for file in $(find . -name "*.md"); do
    # Extract markdown links: [text](link)
    while read -r link; do
        # Skip external links (http/https)
        if [[ "$link" =~ ^https?:// ]]; then
            continue
        fi

        # Skip anchor-only links
        if [[ "$link" =~ ^# ]]; then
            continue
        fi

        # Flag absolute doc paths as broken (should use relative paths)
        if [[ "$link" =~ ^/docs/ ]]; then
            echo "  Absolute link in $file: $link (use relative path instead)"
            BROKEN_LINKS=$((BROKEN_LINKS + 1))
            continue
        fi

        # Skip blog links (resolved by Docusaurus at build time, not filesystem paths)
        if [[ "$link" =~ ^/blog/ ]]; then
            continue
        fi

        # Strip anchor from link for filesystem check
        link_no_anchor="${link%%#*}"
        if [[ -z "$link_no_anchor" ]]; then
            continue
        fi

        # Check if relative path exists
        link_path=$(dirname "$file")/"$link_no_anchor"
        if [[ ! -f "$link_path" ]] && [[ ! -d "$link_path" ]]; then
            echo "  Broken link in $file: $link"
            BROKEN_LINKS=$((BROKEN_LINKS + 1))
        fi
    done < <(grep -oP '\[.*?\]\(\K[^)]+' "$file" 2>/dev/null || true)
done

if [ "$BROKEN_LINKS" -eq 0 ]; then
    pass_test "No broken internal links found"
else
    fail_test "Found $BROKEN_LINKS broken internal link(s)" "Check file paths and fix broken references"
fi

# Test 3: Check for markdown formatting issues
echo ""
echo "Test 3: Checking markdown formatting..."
FORMATTING_ISSUES=0

for file in $(find . -name "*.md"); do
    # Check for unclosed code blocks
    BACKTICK_COUNT=$(grep -o '```' "$file" | wc -l)
    if [ $((BACKTICK_COUNT % 2)) -ne 0 ]; then
        echo "  Unclosed code block in: $file"
        FORMATTING_ISSUES=$((FORMATTING_ISSUES + 1))
    fi

    # Check for frontmatter
    if ! head -1 "$file" | grep -q "^---$"; then
        echo "  Missing frontmatter in: $file"
        FORMATTING_ISSUES=$((FORMATTING_ISSUES + 1))
    fi
done

if [ "$FORMATTING_ISSUES" -eq 0 ]; then
    pass_test "No markdown formatting issues"
else
    fail_test "Found $FORMATTING_ISSUES formatting issue(s)" "Review markdown syntax in flagged files"
fi

# Test 4: Check for TODO/FIXME markers
echo ""
echo "Test 4: Checking for unresolved TODO/FIXME markers..."
TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX" "$ROOT_DIR/docs/" --include="*.md" 2>/dev/null | wc -l)

if [ "$TODO_COUNT" -eq 0 ]; then
    pass_test "No unresolved TODO markers"
else
    echo "  Found $TODO_COUNT TODO/FIXME marker(s) in documentation"
    grep -r "TODO\|FIXME\|XXX" "$ROOT_DIR/docs/" --include="*.md" 2>/dev/null | head -5
    if [ "$TODO_COUNT" -gt 5 ]; then
        echo "  ... and $((TODO_COUNT - 5)) more"
    fi
    # This is a warning, not a failure
    pass_test "TODO markers documented (review for completion)"
fi

# Test 5: Verify required documentation exists
echo ""
echo "Test 5: Verifying required documentation pages exist..."
REQUIRED_DOCS=(
    "docs/index.md"
    "docs/getting-started/installation.md"
    "docs/getting-started/quickstart.md"
    "docs/architecture/overview.md"
    "docs/cli-reference/index.md"
    "docs/operations/troubleshooting.md"
)

MISSING_DOCS=0
for doc in "${REQUIRED_DOCS[@]}"; do
    if [ ! -f "$ROOT_DIR/$doc" ]; then
        echo "  Missing required doc: $doc"
        MISSING_DOCS=$((MISSING_DOCS + 1))
    fi
done

if [ "$MISSING_DOCS" -eq 0 ]; then
    pass_test "All required documentation pages exist"
else
    fail_test "Missing $MISSING_DOCS required documentation page(s)" "Create missing pages"
fi

# Test 6: Check for large files
echo ""
echo "Test 6: Checking for oversized files..."
LARGE_FILES=0
MAX_SIZE_KB=500

while IFS= read -r -d '' file; do
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    size_kb=$((size / 1024))
    if [ "$size_kb" -gt "$MAX_SIZE_KB" ]; then
        echo "  Large file ($size_kb KB): $file"
        LARGE_FILES=$((LARGE_FILES + 1))
    fi
done < <(find "$ROOT_DIR/docs" -name "*.md" -print0)

if [ "$LARGE_FILES" -eq 0 ]; then
    pass_test "No oversized documentation files"
else
    echo "  Warning: Found $LARGE_FILES file(s) over ${MAX_SIZE_KB}KB"
    echo "  Consider splitting large files into smaller pages"
    pass_test "Large files documented (consider splitting)"
fi

# Test 7: Verify sidebar configuration
echo ""
echo "Test 7: Checking sidebar configuration..."
if [ -f "$ROOT_DIR/sidebars.ts" ] || [ -f "$ROOT_DIR/sidebars.js" ]; then
    pass_test "Sidebar configuration exists"
else
    fail_test "Sidebar configuration missing" "Create sidebars.ts or sidebars.js"
fi

# Test 8: Verify all doc files are referenced in sidebar
echo ""
echo "Test 8: Checking sidebar covers all doc files..."
SIDEBAR_FILE=""
if [ -f "$ROOT_DIR/sidebars.ts" ]; then
    SIDEBAR_FILE="$ROOT_DIR/sidebars.ts"
elif [ -f "$ROOT_DIR/sidebars.js" ]; then
    SIDEBAR_FILE="$ROOT_DIR/sidebars.js"
fi

if [ -n "$SIDEBAR_FILE" ]; then
    ORPHANED_DOCS=0
    while IFS= read -r -d '' file; do
        # Get doc ID (relative path without .md extension)
        rel_path="${file#$ROOT_DIR/docs/}"
        doc_id="${rel_path%.md}"

        # Check if this doc ID appears in the sidebar config
        if ! grep -q "'${doc_id}'" "$SIDEBAR_FILE" && \
           ! grep -q "\"${doc_id}\"" "$SIDEBAR_FILE"; then
            echo "  Not in sidebar: docs/$rel_path"
            ORPHANED_DOCS=$((ORPHANED_DOCS + 1))
        fi
    done < <(find "$ROOT_DIR/docs" -name "*.md" -print0)

    if [ "$ORPHANED_DOCS" -eq 0 ]; then
        pass_test "All doc files are referenced in sidebar"
    else
        fail_test "Found $ORPHANED_DOCS doc file(s) not in sidebar" "Add missing pages to sidebars.ts"
    fi
else
    fail_test "No sidebar config found" "Cannot verify sidebar coverage"
fi

# Test 9: Verify top-level CLI commands referenced in docs actually exist
echo ""
echo "Test 9: Checking CLI commands referenced in docs..."
INVALID_CMDS=0

# Skip if gt CLI is not available (e.g., CI environment)
if ! command -v gt >/dev/null 2>&1; then
    echo "  Skipping: gt CLI not available (CI environment)"
    pass_test "CLI command check skipped (gt not available)"
else

# Extract unique "gt <cmd>" top-level commands from fenced code blocks only
# This avoids false positives from prose like "gt commands for..."
TMPFILE=$(mktemp)
find "$ROOT_DIR/docs" -name "*.md" -exec awk '
    /^```/{in_code=!in_code; next}
    in_code && /gt [a-z]/ && !/^[[:space:]]*#/{
        for(i=1;i<=NF;i++){
            if($i=="gt" && i<NF){
                cmd=$(i+1)
                if(cmd ~ /^[a-z][a-z-]*$/){
                    print cmd
                }
            }
        }
    }
' {} + | sort -u > "$TMPFILE"

# Check each unique top-level command
while read -r cmd; do
    # Skip empty, flags, uppercase (likely prose)
    [[ -z "$cmd" ]] && continue
    [[ "$cmd" =~ ^- ]] && continue
    [[ "$cmd" =~ ^[A-Z] ]] && continue

    # Check if command exists via --help
    if ! gt "$cmd" --help >/dev/null 2>&1; then
        echo "  Non-existent command: gt $cmd"
        INVALID_CMDS=$((INVALID_CMDS + 1))
    fi
done < "$TMPFILE"
rm -f "$TMPFILE"

if [ "$INVALID_CMDS" -eq 0 ]; then
    pass_test "All top-level CLI commands in docs are valid"
else
    fail_test "Found $INVALID_CMDS invalid CLI command(s) in docs" "Fix commands to match actual gt CLI"
fi
fi

# Test 10: Check for bare code blocks (missing language specifiers)
echo ""
echo "Test 10: Checking for bare code blocks..."
BARE_BLOCKS=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Track whether we're inside a code block
    in_block=false
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^'```' ]]; then
            if [ "$in_block" = false ]; then
                # Opening fence — check if it has a language tag
                if [[ "$line" =~ ^'```'$ ]]; then
                    echo "  Bare code block in $file:$line_num"
                    BARE_BLOCKS=$((BARE_BLOCKS + 1))
                fi
                in_block=true
            else
                in_block=false
            fi
        fi
    done < "$file"
done

if [ "$BARE_BLOCKS" -eq 0 ]; then
    pass_test "All code blocks have language specifiers"
else
    fail_test "Found $BARE_BLOCKS bare code block(s)" "Add language tags (bash, text, json, etc.) to opening fences"
fi

# Test 11: Check for truncated meta descriptions
echo ""
echo "Test 11: Checking for truncated meta descriptions..."
TRUNCATED_DESCS=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    if grep -q 'description: ".*\.\.\."' "$file" 2>/dev/null; then
        echo "  Truncated description in: $file"
        TRUNCATED_DESCS=$((TRUNCATED_DESCS + 1))
    fi
done

if [ "$TRUNCATED_DESCS" -eq 0 ]; then
    pass_test "All meta descriptions are complete"
else
    fail_test "Found $TRUNCATED_DESCS truncated description(s)" "Replace descriptions ending with '...' with complete sentences"
fi

# Test 12: Check for Related cross-reference sections
echo ""
echo "Test 12: Checking for Related cross-reference sections..."
MISSING_RELATED=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md"); do
    if ! grep -q "^## Related" "$file" 2>/dev/null; then
        echo "  Missing Related section: $file"
        MISSING_RELATED=$((MISSING_RELATED + 1))
    fi
done

if [ "$MISSING_RELATED" -eq 0 ]; then
    pass_test "All non-index pages have Related sections"
else
    fail_test "Found $MISSING_RELATED page(s) without Related sections" "Add ## Related with 3-4 cross-references"
fi

# Test 13: Check for admonition coverage on non-index pages
echo ""
echo "Test 13: Checking for admonition coverage..."
MISSING_ADMONITIONS=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md"); do
    if ! grep -q "^:::" "$file" 2>/dev/null; then
        echo "  No admonitions in: $file"
        MISSING_ADMONITIONS=$((MISSING_ADMONITIONS + 1))
    fi
done

if [ "$MISSING_ADMONITIONS" -eq 0 ]; then
    pass_test "All non-index pages have admonitions"
else
    fail_test "Found $MISSING_ADMONITIONS page(s) without admonitions" "Add :::tip, :::note, or :::warning callouts"
fi

# Test 14: Validate Mermaid diagram syntax
echo ""
echo "Test 14: Checking Mermaid diagram syntax..."
MERMAID_ERRORS=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Extract mermaid blocks and check first line has a valid diagram type
    in_mermaid=false
    first_content_line=true
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^'```mermaid' ]]; then
            in_mermaid=true
            first_content_line=true
            continue
        fi
        if [ "$in_mermaid" = true ] && [[ "$line" =~ ^'```' ]]; then
            in_mermaid=false
            continue
        fi
        if [ "$in_mermaid" = true ] && [ "$first_content_line" = true ]; then
            # Skip blank lines
            [[ -z "${line// }" ]] && continue
            first_content_line=false
            # Check for valid mermaid diagram type declaration
            if ! echo "$line" | grep -qiE "^[[:space:]]*(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|gitgraph|journey|mindmap|timeline|quadrantChart|sankey|xychart|block|packet|architecture|kanban)\b"; then
                echo "  Invalid mermaid diagram type in $file:$line_num: $line"
                MERMAID_ERRORS=$((MERMAID_ERRORS + 1))
            fi
        fi
    done < "$file"
done

if [ "$MERMAID_ERRORS" -eq 0 ]; then
    pass_test "All Mermaid diagrams have valid type declarations"
else
    fail_test "Found $MERMAID_ERRORS invalid Mermaid diagram(s)" "Ensure first line of mermaid block is a valid diagram type (graph, flowchart, sequenceDiagram, etc.)"
fi

# Test 15: Verify frontmatter completeness
echo ""
echo "Test 15: Checking frontmatter completeness..."
MISSING_FRONTMATTER=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Extract frontmatter (between first --- and second ---)
    frontmatter=$(awk '/^---$/{if(++n==2)exit}n==1' "$file" 2>/dev/null)

    if [ -z "$frontmatter" ]; then
        echo "  No frontmatter in: $file"
        MISSING_FRONTMATTER=$((MISSING_FRONTMATTER + 1))
        continue
    fi

    # Check for title
    if ! echo "$frontmatter" | grep -q '^title:'; then
        echo "  Missing title in: $file"
        MISSING_FRONTMATTER=$((MISSING_FRONTMATTER + 1))
    fi

    # Check for description
    if ! echo "$frontmatter" | grep -q '^description:'; then
        echo "  Missing description in: $file"
        MISSING_FRONTMATTER=$((MISSING_FRONTMATTER + 1))
    fi

    # Check for sidebar_position
    if ! echo "$frontmatter" | grep -q '^sidebar_position:'; then
        echo "  Missing sidebar_position in: $file"
        MISSING_FRONTMATTER=$((MISSING_FRONTMATTER + 1))
    fi
done

if [ "$MISSING_FRONTMATTER" -eq 0 ]; then
    pass_test "All pages have complete frontmatter (title, description, sidebar_position)"
else
    fail_test "Found $MISSING_FRONTMATTER frontmatter issue(s)" "Ensure all pages have title, description, and sidebar_position"
fi

# Test 16: Blog post quality checks
echo ""
echo "Test 16: Checking blog post quality..."
BLOG_ISSUES=0

if [ -d "$ROOT_DIR/blog" ]; then
    for file in $(find "$ROOT_DIR/blog" -name "*.md"); do
        basename=$(basename "$file")

        # Check for frontmatter with title and description
        frontmatter=$(awk '/^---$/{if(++n==2)exit}n==1' "$file" 2>/dev/null)
        if [ -z "$frontmatter" ]; then
            echo "  No frontmatter in blog: $basename"
            BLOG_ISSUES=$((BLOG_ISSUES + 1))
        else
            if ! echo "$frontmatter" | grep -q '^title:'; then
                echo "  Missing title in blog: $basename"
                BLOG_ISSUES=$((BLOG_ISSUES + 1))
            fi
            if ! echo "$frontmatter" | grep -q '^description:'; then
                echo "  Missing description in blog: $basename"
                BLOG_ISSUES=$((BLOG_ISSUES + 1))
            fi
            if ! echo "$frontmatter" | grep -q '^tags:'; then
                echo "  Missing tags in blog: $basename"
                BLOG_ISSUES=$((BLOG_ISSUES + 1))
            fi
        fi

        # Check for truncate marker (required for blog list excerpts)
        if ! grep -q '<!-- truncate -->' "$file" 2>/dev/null; then
            echo "  Missing <!-- truncate --> marker in blog: $basename"
            BLOG_ISSUES=$((BLOG_ISSUES + 1))
        fi

        # Check minimum content length (at least 10 lines after frontmatter)
        content_lines=$(awk '/^---$/{if(++n==2){found=1;next}}found{print}' "$file" | wc -l)
        if [ "$content_lines" -lt 10 ]; then
            echo "  Blog post too short ($content_lines lines): $basename"
            BLOG_ISSUES=$((BLOG_ISSUES + 1))
        fi
    done
fi

if [ "$BLOG_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have proper frontmatter, truncate markers, and sufficient content"
else
    fail_test "Found $BLOG_ISSUES blog quality issue(s)" "Ensure blog posts have title, description, tags, truncate marker, and 10+ lines"
fi

# Test 17: Validate anchor links point to existing headings
echo ""
echo "Test 17: Checking anchor links resolve to headings..."
BROKEN_ANCHORS=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Extract links with anchors: [text](path#anchor) or [text](#anchor)
    while read -r link; do
        # Skip external links
        [[ "$link" =~ ^https?:// ]] && continue

        # Must contain a # to be an anchor link
        [[ "$link" != *"#"* ]] && continue

        # Split into path and anchor
        link_path="${link%%#*}"
        anchor="${link#*#}"
        [[ -z "$anchor" ]] && continue

        # Determine target file
        if [[ -z "$link_path" ]]; then
            # Same-file anchor: #heading
            target_file="$file"
        else
            # Cross-file anchor: path#heading
            target_file="$(dirname "$file")/$link_path"
            # Try with .md extension if not found
            if [[ ! -f "$target_file" ]] && [[ ! "$target_file" =~ \.md$ ]]; then
                target_file="${target_file}.md"
            fi
            # Also try as directory index
            if [[ ! -f "$target_file" ]] && [[ -d "${target_file%.md}" ]]; then
                target_file="${target_file%.md}/index.md"
            fi
        fi

        [[ ! -f "$target_file" ]] && continue

        # Convert anchor to expected heading text for comparison
        # Markdown heading anchors are lowercase, spaces become hyphens, special chars removed
        # Check if any heading in the target generates this anchor
        found=false
        while IFS= read -r heading; do
            # Generate anchor from heading: lowercase, replace spaces with hyphens, strip non-alphanumeric (except hyphens)
            generated=$(echo "$heading" | sed 's/^#\+ //' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/-$//')
            if [[ "$generated" == "$anchor" ]]; then
                found=true
                break
            fi
        done < <(grep '^#' "$target_file" 2>/dev/null)

        if [ "$found" = false ]; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Broken anchor in $rel_file: $link"
            BROKEN_ANCHORS=$((BROKEN_ANCHORS + 1))
        fi
    done < <(grep -oP '\[.*?\]\(\K[^)]+' "$file" 2>/dev/null || true)
done

if [ "$BROKEN_ANCHORS" -eq 0 ]; then
    pass_test "All anchor links resolve to valid headings"
else
    fail_test "Found $BROKEN_ANCHORS broken anchor link(s)" "Fix heading references to match actual heading text"
fi

# Test 18: Check that Mermaid diagrams have accessible descriptions nearby
echo ""
echo "Test 18: Checking Mermaid diagram accessibility..."
MERMAID_ACCESS_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Count mermaid blocks in this file
    mermaid_count=$(grep -c '```mermaid' "$file" 2>/dev/null || true)
    mermaid_count="${mermaid_count:-0}"
    if [ "$mermaid_count" -gt 0 ] 2>/dev/null; then
        # Check that the file has at least as many headings or descriptive text near diagrams
        # Specifically: every mermaid block should be preceded by a heading or paragraph within 5 lines
        line_num=0
        last_text_line=0
        while IFS= read -r line; do
            line_num=$((line_num + 1))
            # Track lines with text content (not blank, not code fence)
            if [[ -n "${line// }" ]] && [[ ! "$line" =~ ^'```' ]]; then
                last_text_line=$line_num
            fi
            # Check mermaid blocks
            if [[ "$line" =~ ^'```mermaid' ]]; then
                gap=$((line_num - last_text_line))
                if [ "$gap" -gt 5 ] && [ "$last_text_line" -gt 0 ]; then
                    rel_file="${file#$ROOT_DIR/}"
                    echo "  Mermaid diagram without nearby description in $rel_file:$line_num (gap: $gap lines)"
                    MERMAID_ACCESS_ISSUES=$((MERMAID_ACCESS_ISSUES + 1))
                fi
            fi
        done < "$file"
    fi
done

if [ "$MERMAID_ACCESS_ISSUES" -eq 0 ]; then
    pass_test "All Mermaid diagrams have nearby descriptive text"
else
    fail_test "Found $MERMAID_ACCESS_ISSUES Mermaid diagram(s) without nearby descriptions" "Add explanatory text above Mermaid diagrams"
fi

# Test 19: Check for duplicate headings within a single page
echo ""
echo "Test 19: Checking for duplicate headings..."
DUPLICATE_HEADINGS=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Extract all headings (## and below), normalize
    headings=$(grep '^##' "$file" 2>/dev/null | sed 's/^##* //' | sort)
    dupes=$(echo "$headings" | uniq -d)
    if [ -n "$dupes" ]; then
        rel_file="${file#$ROOT_DIR/}"
        while IFS= read -r dupe; do
            [ -z "$dupe" ] && continue
            echo "  Duplicate heading in $rel_file: \"$dupe\""
            DUPLICATE_HEADINGS=$((DUPLICATE_HEADINGS + 1))
        done <<< "$dupes"
    fi
done

if [ "$DUPLICATE_HEADINGS" -eq 0 ]; then
    pass_test "No duplicate headings found within pages"
else
    fail_test "Found $DUPLICATE_HEADINGS duplicate heading(s)" "Rename duplicate headings to be unique within each page"
fi

# Test 20: Validate external link format (well-formed URLs, no placeholder domains)
echo ""
echo "Test 20: Checking external link format..."
BAD_URLS=0

for file in $(find "$ROOT_DIR/docs" "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    while read -r link; do
        # Only check external links
        [[ ! "$link" =~ ^https?:// ]] && continue

        # Check for placeholder/example domains that shouldn't be in docs
        if echo "$link" | grep -qiE '(example\.com|placeholder\.|your-domain|localhost:[0-9]|127\.0\.0\.1)'; then
            # Allow example.com in explicitly example contexts
            continue
        fi

        # Check for obviously malformed URLs (double slashes after domain, trailing dots)
        if echo "$link" | grep -qE 'https?://[^/]*\.\.' ; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Malformed URL in $rel_file: $link"
            BAD_URLS=$((BAD_URLS + 1))
        fi

        # Check for URLs with spaces (common copy-paste error)
        if echo "$link" | grep -q ' '; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  URL contains spaces in $rel_file: $link"
            BAD_URLS=$((BAD_URLS + 1))
        fi

        # Check for incomplete URLs (just protocol)
        if [[ "$link" =~ ^https?://$ ]]; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Incomplete URL in $rel_file: $link"
            BAD_URLS=$((BAD_URLS + 1))
        fi
    done < <(grep -oP '\[.*?\]\(\K[^)]+' "$file" 2>/dev/null || true)
done

if [ "$BAD_URLS" -eq 0 ]; then
    pass_test "All external links are well-formed"
else
    fail_test "Found $BAD_URLS malformed external link(s)" "Fix URL formatting issues"
fi

# Test 21: Check for inconsistent terminology
echo ""
echo "Test 21: Checking terminology consistency..."
TERM_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    in_code=false
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^'```' ]]; then
            in_code=$([ "$in_code" = false ] && echo true || echo false)
            continue
        fi
        [ "$in_code" = true ] && continue
        # Skip frontmatter lines
        [[ "$line" =~ ^--- ]] && continue

        rel_file="${file#$ROOT_DIR/}"

        # Check: "pole cat" or "pole-cat" (should be "polecat")
        if echo "$line" | grep -qi '\bpole[- ]cat\b' 2>/dev/null; then
            echo "  Inconsistent term 'pole cat/pole-cat' in $rel_file:$line_num (use 'polecat')"
            TERM_ISSUES=$((TERM_ISSUES + 1))
        fi

        # Check: "gasetown" (common misspelling)
        if echo "$line" | grep -qi '\bgasetown\b' 2>/dev/null; then
            echo "  Misspelling 'gasetown' in $rel_file:$line_num (use 'Gas Town' or 'Gastown')"
            TERM_ISSUES=$((TERM_ISSUES + 1))
        fi

        # Check: "work tree" (should be "worktree")
        if echo "$line" | grep -qi '\bwork tree\b' 2>/dev/null; then
            echo "  Inconsistent term 'work tree' in $rel_file:$line_num (use 'worktree')"
            TERM_ISSUES=$((TERM_ISSUES + 1))
        fi
    done < "$file"
done

if [ "$TERM_ISSUES" -eq 0 ]; then
    pass_test "Terminology is consistent across documentation"
else
    fail_test "Found $TERM_ISSUES terminology inconsistenc(ies)" "Use canonical terms: Gas Town/Gastown, polecat, worktree"
fi

# Test 22: Validate heading hierarchy (no skipped levels)
echo ""
echo "Test 22: Checking heading hierarchy..."
HEADING_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Extract headings outside code blocks, check hierarchy
    # Use awk to reliably handle nested code fences
    prev_level=1
    while IFS= read -r heading_info; do
        level="${heading_info%%:*}"
        rest="${heading_info#*:}"
        lnum="${rest%%:*}"
        # Only check h2+ (h1 is the page title, and # appears in code comments)
        [ "$level" -le 1 ] && continue
        if [ "$level" -gt $((prev_level + 1)) ] && [ "$prev_level" -gt 0 ]; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Skipped heading level in $rel_file:$lnum (h$prev_level → h$level)"
            HEADING_ISSUES=$((HEADING_ISSUES + 1))
        fi
        prev_level=$level
    done < <(awk '
        /^---$/ && NR<=2 { in_fm=!in_fm; next }
        in_fm { next }
        /^```/ { in_code=!in_code; next }
        in_code { next }
        /^##+ / {
            match($0, /^(#+) /, arr)
            level = length(arr[1])
            print level ":" NR ":" $0
        }
    ' "$file")
done

if [ "$HEADING_ISSUES" -eq 0 ]; then
    pass_test "All heading hierarchies are properly nested"
else
    fail_test "Found $HEADING_ISSUES heading hierarchy issue(s)" "Don't skip heading levels (e.g. ## → #### without ###)"
fi

# Test 23: Check for empty code blocks
echo ""
echo "Test 23: Checking for empty code blocks..."
EMPTY_BLOCKS=0

for file in $(find "$ROOT_DIR/docs" "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Use awk to find code blocks with no content between fences
    while IFS= read -r block_info; do
        rel_file="${file#$ROOT_DIR/}"
        echo "  Empty code block in $rel_file:$block_info"
        EMPTY_BLOCKS=$((EMPTY_BLOCKS + 1))
    done < <(awk '
        /^```/ {
            if (in_block) {
                # Closing fence — check if block was empty
                if (content_lines == 0) {
                    print start_line
                }
                in_block = 0
            } else {
                # Opening fence
                in_block = 1
                start_line = NR
                content_lines = 0
            }
            next
        }
        in_block {
            # Count non-empty lines
            if ($0 !~ /^[[:space:]]*$/) content_lines++
        }
    ' "$file")
done

if [ "$EMPTY_BLOCKS" -eq 0 ]; then
    pass_test "No empty code blocks found"
else
    fail_test "Found $EMPTY_BLOCKS empty code block(s)" "Add content or remove empty code blocks"
fi

# Test 24: Validate meta description length (SEO best practice: 50-160 chars)
echo ""
echo "Test 24: Checking meta description lengths..."
DESC_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Extract description from frontmatter
    desc=$(awk '/^---$/{if(++n==2)exit}n==1 && /^description:/{
        sub(/^description:[[:space:]]*"?/, ""); sub(/"[[:space:]]*$/, ""); print
    }' "$file" 2>/dev/null)

    [ -z "$desc" ] && continue

    desc_len=${#desc}
    rel_file="${file#$ROOT_DIR/}"

    if [ "$desc_len" -lt 50 ]; then
        echo "  Short description ($desc_len chars) in $rel_file"
        DESC_ISSUES=$((DESC_ISSUES + 1))
    elif [ "$desc_len" -gt 160 ]; then
        echo "  Long description ($desc_len chars) in $rel_file"
        DESC_ISSUES=$((DESC_ISSUES + 1))
    fi
done

if [ "$DESC_ISSUES" -eq 0 ]; then
    pass_test "All meta descriptions are within SEO range (50-160 chars)"
else
    fail_test "Found $DESC_ISSUES description(s) outside optimal length" "Aim for 50-160 character descriptions"
fi

# Test 25: Validate admonition syntax (matching ::: openers and closers)
echo ""
echo "Test 25: Checking admonition syntax..."
ADMONITION_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md"); do
    # Count ::: openers (with type) and ::: closers (bare)
    # Openers: :::tip, :::note, :::warning, :::info, :::caution, :::danger
    openers=$(grep -cE '^:::[a-z]' "$file" 2>/dev/null | tail -1)
    closers=$(grep -cE '^:::$' "$file" 2>/dev/null | tail -1)
    openers="${openers:-0}"
    closers="${closers:-0}"

    if [ "$openers" -ne "$closers" ] 2>/dev/null; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Unbalanced admonitions in $rel_file ($openers openers, $closers closers)"
        ADMONITION_ISSUES=$((ADMONITION_ISSUES + 1))
    fi
done

if [ "$ADMONITION_ISSUES" -eq 0 ]; then
    pass_test "All admonitions have matching open/close syntax"
else
    fail_test "Found $ADMONITION_ISSUES file(s) with unbalanced admonitions" "Ensure every :::type has a matching :::"
fi

# Test 26: Validate Related sections have enough cross-references
echo ""
echo "Test 26: Checking Related section quality..."
RELATED_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md"); do
    # Check if file has a Related section
    if ! grep -q '^## Related' "$file" 2>/dev/null; then
        continue  # Test 12 already catches missing Related sections
    fi

    # Count links in the Related section (from ## Related to next ## or EOF)
    link_count=$(awk '/^## Related/{found=1;next} found && /^## /{exit} found' "$file" | grep -cE '\[.*\]\(.*\)' 2>/dev/null || echo 0)

    if [ "$link_count" -lt 2 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Too few links in Related section ($link_count) in $rel_file"
        RELATED_ISSUES=$((RELATED_ISSUES + 1))
    fi
done

if [ "$RELATED_ISSUES" -eq 0 ]; then
    pass_test "All Related sections have sufficient cross-references (2+)"
else
    fail_test "Found $RELATED_ISSUES Related section(s) with too few links" "Add at least 2 cross-reference links to each Related section"
fi

# Test 27: Blog posts have Next Steps sections
echo ""
echo "Test 27: Checking blog posts have Next Steps sections..."
BLOG_NEXTSTEPS_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Skip the welcome post (it has "Getting Started" instead)
    basename=$(basename "$file")
    [ "$basename" = "2026-02-04-welcome.md" ] && continue

    if ! grep -qE '^## (Next Steps|Further Reading)' "$file" 2>/dev/null; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Missing Next Steps/Further Reading section in $rel_file"
        BLOG_NEXTSTEPS_ISSUES=$((BLOG_NEXTSTEPS_ISSUES + 1))
    fi
done

if [ "$BLOG_NEXTSTEPS_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have Next Steps or Further Reading sections"
else
    fail_test "Found $BLOG_NEXTSTEPS_ISSUES blog post(s) without Next Steps/Further Reading" "Add ## Next Steps with links to related docs and blog posts"
fi

# Test 28: Check for consistent frontmatter description quoting
echo ""
echo "Test 28: Checking frontmatter description formatting..."
DESC_FORMAT_ISSUES=0

for file in $(find "$ROOT_DIR/docs" "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Check that descriptions with colons or special chars are quoted
    desc_line=$(awk '/^---$/{if(++n==2)exit}n==1 && /^description:/{print; exit}' "$file" 2>/dev/null)
    [ -z "$desc_line" ] && continue

    # Extract the value after "description: "
    desc_val=$(echo "$desc_line" | sed 's/^description:[[:space:]]*//')

    # If the value contains a colon but is NOT quoted, flag it
    if echo "$desc_val" | grep -q ':' 2>/dev/null; then
        if ! echo "$desc_val" | grep -qE '^".*"$' 2>/dev/null; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Unquoted description with colon in $rel_file"
            DESC_FORMAT_ISSUES=$((DESC_FORMAT_ISSUES + 1))
        fi
    fi
done

if [ "$DESC_FORMAT_ISSUES" -eq 0 ]; then
    pass_test "All frontmatter descriptions are properly formatted"
else
    fail_test "Found $DESC_FORMAT_ISSUES description(s) with unquoted colons" "Wrap descriptions containing colons in double quotes"
fi

# Test 29: All non-index doc pages have at least one code block or Mermaid diagram
echo ""
echo "Test 29: Checking doc pages have code examples or diagrams..."
NO_CODE_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" 2>/dev/null); do
    basename=$(basename "$file")
    # Skip index pages — they are navigation hubs, not content pages
    [ "$basename" = "index.md" ] && continue

    # Count code blocks (``` markers come in pairs, so divide by 2)
    code_blocks=$(grep -c '^```' "$file" 2>/dev/null) || code_blocks=0

    if [ "$code_blocks" -lt 2 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  No code blocks or diagrams in $rel_file"
        NO_CODE_ISSUES=$((NO_CODE_ISSUES + 1))
    fi
done

if [ "$NO_CODE_ISSUES" -eq 0 ]; then
    pass_test "All non-index doc pages have code examples or diagrams"
else
    fail_test "Found $NO_CODE_ISSUES page(s) without code examples or diagrams" "Add at least one code block or Mermaid diagram to each content page"
fi

# Test 30: Blog post tags are non-empty and lowercase
echo ""
echo "Test 30: Checking blog post tag formatting..."
TAG_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Extract tags line from frontmatter
    tags_line=$(awk '/^---$/{if(++n==2)exit}n==1 && /^tags:/{print; exit}' "$file" 2>/dev/null)
    [ -z "$tags_line" ] && continue

    # Check for uppercase letters in tags
    if echo "$tags_line" | grep -qE '\[.*[A-Z].*\]' 2>/dev/null; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Uppercase tag in $rel_file: $tags_line"
        TAG_ISSUES=$((TAG_ISSUES + 1))
    fi
done

if [ "$TAG_ISSUES" -eq 0 ]; then
    pass_test "All blog post tags are properly formatted"
else
    fail_test "Found $TAG_ISSUES blog post(s) with formatting issues in tags" "Use lowercase, hyphenated tags"
fi

# Test 31: Blog posts link back to docs (Next Steps sections with doc links)
echo ""
echo "Test 31: Checking blog posts link back to documentation..."
BLOG_DOC_LINK_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Check if blog post has at least one link to /docs/
    doc_links=$(grep -c '/docs/' "$file" 2>/dev/null) || doc_links=0
    if [ "$doc_links" -lt 1 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  No doc cross-links in $rel_file"
        BLOG_DOC_LINK_ISSUES=$((BLOG_DOC_LINK_ISSUES + 1))
    fi
done

if [ "$BLOG_DOC_LINK_ISSUES" -eq 0 ]; then
    pass_test "All blog posts link back to documentation"
else
    fail_test "Found $BLOG_DOC_LINK_ISSUES blog post(s) without doc cross-links" "Add at least one link to /docs/ in each blog post's Next Steps section"
fi

# Test 32: Doc-to-blog cross-links reference valid blog slugs
echo ""
echo "Test 32: Checking doc-to-blog links reference valid slugs..."
BLOG_SLUG_ISSUES=0

# Build list of valid blog slugs
VALID_SLUGS=""
for blog_file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    slug=$(awk '/^---$/{if(++n==2)exit}n==1 && /^slug:/{print $2; exit}' "$blog_file" 2>/dev/null)
    [ -n "$slug" ] && VALID_SLUGS="$VALID_SLUGS $slug"
done

# Check all /blog/ references in docs
for file in $(find "$ROOT_DIR/docs" -name "*.md" 2>/dev/null); do
    while read -r blog_link; do
        # Extract slug from /blog/slug-name format
        slug=$(echo "$blog_link" | sed 's|^/blog/||' | sed 's|/$||')
        [ -z "$slug" ] && continue
        if ! echo "$VALID_SLUGS" | grep -qw "$slug"; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Invalid blog slug '/blog/$slug' in $rel_file"
            BLOG_SLUG_ISSUES=$((BLOG_SLUG_ISSUES + 1))
        fi
    done < <(grep -oP '\(/blog/[a-z0-9-]+\)' "$file" 2>/dev/null | sed 's/[()]//g' | sort -u || true)
done

if [ "$BLOG_SLUG_ISSUES" -eq 0 ]; then
    pass_test "All doc-to-blog links reference valid blog slugs"
else
    fail_test "Found $BLOG_SLUG_ISSUES invalid blog slug reference(s)" "Ensure blog slugs in docs match actual blog post slugs"
fi

# Test 33: Blog posts cover core topic areas
echo ""
echo "Test 33: Checking blog coverage of core topic areas..."
COVERAGE_ISSUES=0

# Core topic areas that should have at least one blog post
REQUIRED_TOPICS="agents architecture concepts operations workflow"

for topic in $REQUIRED_TOPICS; do
    topic_count=0
    for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
        tags_line=$(awk '/^---$/{if(++n==2)exit}n==1 && /^tags:/{print; exit}' "$file" 2>/dev/null)
        if echo "$tags_line" | grep -qi "$topic"; then
            topic_count=$((topic_count + 1))
        fi
    done
    if [ "$topic_count" -lt 1 ]; then
        echo "  No blog posts tagged with '$topic'"
        COVERAGE_ISSUES=$((COVERAGE_ISSUES + 1))
    fi
done

if [ "$COVERAGE_ISSUES" -eq 0 ]; then
    pass_test "Blog posts cover all core topic areas"
else
    fail_test "Missing blog coverage for $COVERAGE_ISSUES topic area(s)" "Add blog posts tagged with the missing topics"
fi

# Test 34: Validate Mermaid diagram chart types
echo ""
echo "Test 34: Checking Mermaid diagram chart types..."
MERMAID_TYPE_ISSUES=0
VALID_MERMAID_TYPES="graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|stateDiagram-v2|erDiagram|gantt|pie|gitgraph|journey|mindmap|timeline|quadrantChart|sankey|xychart|block|packet|architecture|kanban"

for file in $(find "$ROOT_DIR/docs" "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    while IFS= read -r type_line; do
        line_num="${type_line%%:*}"
        chart_type="${type_line#*:}"
        chart_type=$(echo "$chart_type" | sed 's/^[[:space:]]*//' | awk '{print $1}')
        if ! echo "$chart_type" | grep -qE "^($VALID_MERMAID_TYPES)$"; then
            rel_file="${file#$ROOT_DIR/}"
            echo "  Invalid Mermaid type '$chart_type' in $rel_file:$line_num"
            MERMAID_TYPE_ISSUES=$((MERMAID_TYPE_ISSUES + 1))
        fi
    done < <(awk '
        /^```mermaid/ { in_mermaid=1; next }
        in_mermaid && /^[a-zA-Z]/ { print NR ":" $0; in_mermaid=0 }
        /^```$/ { in_mermaid=0 }
    ' "$file")
done

if [ "$MERMAID_TYPE_ISSUES" -eq 0 ]; then
    pass_test "All Mermaid diagrams use valid chart types"
else
    fail_test "Found $MERMAID_TYPE_ISSUES invalid Mermaid chart type(s)" "Use valid types: graph, flowchart, sequenceDiagram, pie, stateDiagram-v2, etc."
fi

# Test 35: Validate blog post authors are defined in authors.yml
echo ""
echo "Test 35: Checking blog post authors are defined..."
AUTHOR_ISSUES=0
AUTHORS_FILE="$ROOT_DIR/blog/authors.yml"

if [ -f "$AUTHORS_FILE" ]; then
    # Extract defined author keys from authors.yml (lines that start with a word and colon at root level)
    DEFINED_AUTHORS=$(grep -E '^[a-z][a-z0-9_-]*:' "$AUTHORS_FILE" | sed 's/:.*//' | tr '\n' ' ')

    for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
        authors_line=$(awk '/^---$/{if(++n==2)exit}n==1 && /^authors:/{print; exit}' "$file" 2>/dev/null)
        [ -z "$authors_line" ] && continue

        # Extract author names from [brackets]
        authors=$(echo "$authors_line" | grep -oP '\[\K[^\]]+' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        for author in $authors; do
            if ! echo "$DEFINED_AUTHORS" | grep -qw "$author"; then
                rel_file="${file#$ROOT_DIR/}"
                echo "  Undefined author '$author' in $rel_file"
                AUTHOR_ISSUES=$((AUTHOR_ISSUES + 1))
            fi
        done
    done
fi

if [ "$AUTHOR_ISSUES" -eq 0 ]; then
    pass_test "All blog post authors are defined in authors.yml"
else
    fail_test "Found $AUTHOR_ISSUES undefined blog author(s)" "Add missing authors to blog/authors.yml"
fi

# Test 36: All doc pages have Mermaid diagrams
echo ""
echo "Test 36: Checking all doc pages have Mermaid diagrams..."
MERMAID_MISSING=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" 2>/dev/null); do
    basename=$(basename "$file")
    # Skip index pages (they are navigation hubs, not content pages)
    [ "$basename" = "index.md" ] && continue

    if ! grep -q '```mermaid' "$file" 2>/dev/null; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Missing Mermaid diagram in $rel_file"
        MERMAID_MISSING=$((MERMAID_MISSING + 1))
    fi
done

if [ "$MERMAID_MISSING" -eq 0 ]; then
    pass_test "All doc pages have at least one Mermaid diagram"
else
    fail_test "Found $MERMAID_MISSING doc page(s) without Mermaid diagrams" "Add a relevant Mermaid diagram to each doc page for visual clarity"
fi

# Test 37: All doc pages have 3+ blog post cross-links
echo ""
echo "Test 37: Checking all doc pages have 3+ blog post cross-links..."
BLOG_CROSSLINK_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" 2>/dev/null); do
    basename=$(basename "$file")
    # Skip index pages (they are navigation hubs, not content pages)
    [ "$basename" = "index.md" ] && continue

    # Count links to /blog/ in the file
    blog_link_count=$(grep -coP '/blog/[a-z0-9-]+' "$file" 2>/dev/null) || blog_link_count=0

    if [ "$blog_link_count" -lt 3 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Only $blog_link_count blog link(s) in $rel_file (need 3+)"
        BLOG_CROSSLINK_ISSUES=$((BLOG_CROSSLINK_ISSUES + 1))
    fi
done

if [ "$BLOG_CROSSLINK_ISSUES" -eq 0 ]; then
    pass_test "All doc pages have 3+ blog post cross-links"
else
    fail_test "Found $BLOG_CROSSLINK_ISSUES doc page(s) with fewer than 2 blog cross-links" "Add at least 2 /blog/ links to each doc page's Related section"
fi

# Test 38: Blog post meta description lengths within SEO range (50-160 chars)
echo ""
echo "Test 38: Checking blog post meta description lengths..."
BLOG_DESC_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    desc=$(awk '/^---$/{if(++n==2)exit}n==1 && /^description:/{
        sub(/^description:[[:space:]]*"?/, ""); sub(/"[[:space:]]*$/, ""); print
    }' "$file" 2>/dev/null)

    [ -z "$desc" ] && continue

    desc_len=${#desc}
    rel_file="${file#$ROOT_DIR/}"

    if [ "$desc_len" -lt 50 ]; then
        echo "  Short description ($desc_len chars) in $rel_file"
        BLOG_DESC_ISSUES=$((BLOG_DESC_ISSUES + 1))
    elif [ "$desc_len" -gt 160 ]; then
        echo "  Long description ($desc_len chars) in $rel_file"
        BLOG_DESC_ISSUES=$((BLOG_DESC_ISSUES + 1))
    fi
done

if [ "$BLOG_DESC_ISSUES" -eq 0 ]; then
    pass_test "All blog post meta descriptions are within SEO range (50-160 chars)"
else
    fail_test "Found $BLOG_DESC_ISSUES blog description(s) outside optimal length" "Aim for 50-160 character blog descriptions"
fi

# Test 39: Blog posts link to at least 2 other blog posts
echo ""
echo "Test 39: Checking blog-to-blog cross-linking..."
BLOG_INTERLINK_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Count links to other blog posts
    blog_link_count=$(grep -coP '/blog/[a-z0-9-]+' "$file" 2>/dev/null) || blog_link_count=0

    if [ "$blog_link_count" -lt 4 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Only $blog_link_count blog link(s) in $rel_file (need 4+)"
        BLOG_INTERLINK_ISSUES=$((BLOG_INTERLINK_ISSUES + 1))
    fi
done

if [ "$BLOG_INTERLINK_ISSUES" -eq 0 ]; then
    pass_test "All blog posts link to 4+ other blog posts"
else
    fail_test "Found $BLOG_INTERLINK_ISSUES blog post(s) with fewer than 3 blog cross-links" "Add links to related blog posts in the Next Steps section"
fi

# Test 40: No orphaned blog slugs (every slug referenced by at least 1 doc page)
echo ""
echo "Test 40: Checking for orphaned blog slugs..."
ORPHAN_ISSUES=0

for blog_file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    slug=$(awk '/^---$/{if(++n==2)exit}n==1 && /^slug:/{print $2; exit}' "$blog_file" 2>/dev/null)
    [ -z "$slug" ] && continue

    # Check if any doc page references this slug
    refs=$(grep -rl "/blog/$slug" "$ROOT_DIR/docs/" 2>/dev/null | wc -l)
    if [ "$refs" -eq 0 ]; then
        rel_file="${blog_file#$ROOT_DIR/}"
        echo "  Orphaned blog slug '/blog/$slug' in $rel_file (not referenced by any doc page)"
        ORPHAN_ISSUES=$((ORPHAN_ISSUES + 1))
    fi
done

if [ "$ORPHAN_ISSUES" -eq 0 ]; then
    pass_test "All blog slugs are referenced by at least one doc page"
else
    fail_test "Found $ORPHAN_ISSUES orphaned blog slug(s)" "Add a link to each orphaned blog post from a relevant doc page's Blog Posts section"
fi

# Test 41: All blog posts have Mermaid diagrams
echo ""
echo "Test 41: Checking all blog posts have Mermaid diagrams..."
BLOG_MERMAID_MISSING=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    if ! grep -q '```mermaid' "$file" 2>/dev/null; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Missing Mermaid diagram in $rel_file"
        BLOG_MERMAID_MISSING=$((BLOG_MERMAID_MISSING + 1))
    fi
done

if [ "$BLOG_MERMAID_MISSING" -eq 0 ]; then
    pass_test "All blog posts have at least one Mermaid diagram"
else
    fail_test "Found $BLOG_MERMAID_MISSING blog post(s) without Mermaid diagrams" "Add a relevant Mermaid diagram to each blog post for visual clarity"
fi

# Test 42: Blog posts have sufficient content (200+ words after truncate)
echo ""
echo "Test 42: Checking blog post content length..."
BLOG_LENGTH_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    # Count words after the <!-- truncate --> marker
    word_count=$(awk '/<!-- truncate -->/{found=1;next} found{print}' "$file" | wc -w 2>/dev/null)
    word_count="${word_count:-0}"

    if [ "$word_count" -lt 200 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Short blog post ($word_count words after truncate) in $rel_file"
        BLOG_LENGTH_ISSUES=$((BLOG_LENGTH_ISSUES + 1))
    fi
done

if [ "$BLOG_LENGTH_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have 200+ words of content after truncate marker"
else
    fail_test "Found $BLOG_LENGTH_ISSUES blog post(s) with insufficient content" "Blog posts should have at least 200 words after the truncate marker"
fi

# Test 43: All blog posts have 2+ Mermaid diagrams
echo ""
echo "Test 43: Checking all blog posts have 2+ Mermaid diagrams..."
BLOG_MULTI_MERMAID_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    mermaid_count=$(grep -c '```mermaid' "$file" 2>/dev/null) || mermaid_count=0

    if [ "$mermaid_count" -lt 2 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Only $mermaid_count diagram(s) in $rel_file (need 2+)"
        BLOG_MULTI_MERMAID_ISSUES=$((BLOG_MULTI_MERMAID_ISSUES + 1))
    fi
done

if [ "$BLOG_MULTI_MERMAID_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have 2+ Mermaid diagrams"
else
    fail_test "Found $BLOG_MULTI_MERMAID_ISSUES blog post(s) with fewer than 2 Mermaid diagrams" "Add at least 2 Mermaid diagrams to each blog post"
fi

# Test 44: All blog posts have 4+ /docs/ cross-links
echo ""
echo "Test 44: Checking all blog posts have 4+ /docs/ cross-links..."
BLOG_DOCS_LINK_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    docs_link_count=$(grep -co '/docs/' "$file" 2>/dev/null) || docs_link_count=0

    if [ "$docs_link_count" -lt 4 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Only $docs_link_count /docs/ link(s) in $rel_file (need 4+)"
        BLOG_DOCS_LINK_ISSUES=$((BLOG_DOCS_LINK_ISSUES + 1))
    fi
done

if [ "$BLOG_DOCS_LINK_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have 4+ /docs/ cross-links"
else
    fail_test "Found $BLOG_DOCS_LINK_ISSUES blog post(s) with fewer than 3 /docs/ links" "Add /docs/ cross-links to blog posts for better navigation"
fi

# Test 45: All non-index doc pages have 4+ admonitions
echo ""
echo "Test 45: Checking all non-index doc pages have 4+ admonitions..."
DOC_ADMONITION_ISSUES=0

for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md" 2>/dev/null); do
    # Count opening admonition tags (:::tip, :::note, :::warning, :::info, :::danger, :::caution)
    admonition_count=$(grep -cE '^:::(tip|note|warning|info|danger|caution)' "$file" 2>/dev/null) || admonition_count=0

    if [ "$admonition_count" -lt 4 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Only $admonition_count admonition(s) in $rel_file (need 4+)"
        DOC_ADMONITION_ISSUES=$((DOC_ADMONITION_ISSUES + 1))
    fi
done

if [ "$DOC_ADMONITION_ISSUES" -eq 0 ]; then
    pass_test "All non-index doc pages have 4+ admonitions"
else
    fail_test "Found $DOC_ADMONITION_ISSUES doc page(s) with fewer than 4 admonitions" "Add admonitions (:::tip, :::note, :::warning) to doc pages"
fi

# Test 46: All blog posts have 1000+ total words
echo ""
echo "Test 46: Checking all blog posts have 1000+ total words..."
BLOG_TOTAL_LENGTH_ISSUES=0

for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    word_count=$(wc -w < "$file" 2>/dev/null)
    word_count="${word_count:-0}"

    if [ "$word_count" -lt 1000 ]; then
        rel_file="${file#$ROOT_DIR/}"
        echo "  Only $word_count words in $rel_file (need 1000+)"
        BLOG_TOTAL_LENGTH_ISSUES=$((BLOG_TOTAL_LENGTH_ISSUES + 1))
    fi
done

if [ "$BLOG_TOTAL_LENGTH_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have 1000+ total words"
else
    fail_test "Found $BLOG_TOTAL_LENGTH_ISSUES blog post(s) with fewer than 1000 words" "Expand blog posts to at least 1000 words for substantive content"
fi

# Test 47: All non-index doc pages have 2+ Mermaid diagrams
DOC_MERMAID2_ISSUES=0
echo "Test 47: Checking all non-index doc pages have 2+ Mermaid diagrams..."
for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md" 2>/dev/null); do
    mermaid_count=$(grep -c '```mermaid' "$file" 2>/dev/null) || mermaid_count=0
    if [ "$mermaid_count" -lt 2 ]; then
        echo "  WARNING: $(basename "$file") has only $mermaid_count Mermaid diagram(s)"
        DOC_MERMAID2_ISSUES=$((DOC_MERMAID2_ISSUES + 1))
    fi
done
if [ "$DOC_MERMAID2_ISSUES" -eq 0 ]; then
    pass_test "All non-index doc pages have 2+ Mermaid diagrams"
else
    fail_test "Found $DOC_MERMAID2_ISSUES non-index doc page(s) with fewer than 2 Mermaid diagrams" "Add Mermaid diagrams to doc pages for visual explanations"
fi

# Test 48: All non-index doc pages have 500+ total words
DOC_WORD_COUNT_ISSUES=0
echo "Test 48: Checking all non-index doc pages have 500+ total words..."
for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md" 2>/dev/null); do
    word_count=$(wc -w < "$file" 2>/dev/null)
    if [ "$word_count" -lt 500 ]; then
        echo "  WARNING: $(basename "$file") has only $word_count words"
        DOC_WORD_COUNT_ISSUES=$((DOC_WORD_COUNT_ISSUES + 1))
    fi
done
if [ "$DOC_WORD_COUNT_ISSUES" -eq 0 ]; then
    pass_test "All non-index doc pages have 500+ total words"
else
    fail_test "Found $DOC_WORD_COUNT_ISSUES non-index doc page(s) with fewer than 500 words" "Expand doc pages to at least 500 words for substantive content"
fi

# Test 49: No orphaned doc pages (every non-index doc page referenced by at least 1 other page)
ORPHANED_DOC_ISSUES=0
echo "Test 49: Checking for orphaned doc pages..."
for file in $(find "$ROOT_DIR/docs" -name "*.md" ! -name "index.md" 2>/dev/null); do
    # Extract the doc URL path (e.g., /docs/cli-reference/agents)
    rel_path="${file#$ROOT_DIR/}"
    doc_url="/${rel_path%.md}"
    # Search for this URL in all other md files
    ref_count=$(grep -rl "$doc_url" "$ROOT_DIR/docs" "$ROOT_DIR/blog" 2>/dev/null | grep -v "$file" | wc -l)
    if [ "$ref_count" -eq 0 ]; then
        echo "  WARNING: $doc_url is not referenced by any other page"
        ORPHANED_DOC_ISSUES=$((ORPHANED_DOC_ISSUES + 1))
    fi
done
if [ "$ORPHANED_DOC_ISSUES" -eq 0 ]; then
    pass_test "All non-index doc pages are referenced by at least one other page"
else
    fail_test "Found $ORPHANED_DOC_ISSUES orphaned doc page(s) with no inbound references" "Add cross-links from related docs or blog posts"
fi

# Test 50: All blog posts have at least one markdown table
BLOG_TABLE_ISSUES=0
echo "Test 50: Checking all blog posts have at least one markdown table..."
for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    table_rows=$(grep -c '|.*|.*|' "$file" 2>/dev/null) || table_rows=0
    if [ "$table_rows" -lt 2 ]; then
        echo "  WARNING: $(basename "$file") has no markdown table"
        BLOG_TABLE_ISSUES=$((BLOG_TABLE_ISSUES + 1))
    fi
done
if [ "$BLOG_TABLE_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have at least one markdown table"
else
    fail_test "Found $BLOG_TABLE_ISSUES blog post(s) without markdown tables" "Add a comparison or reference table to each blog post"
fi

# Test 51: All blog posts have at least 2 admonitions
BLOG_ADMONITION_ISSUES=0
echo "Test 51: Checking all blog posts have 2+ admonitions..."
for file in $(find "$ROOT_DIR/blog" -name "*.md" 2>/dev/null); do
    admonition_count=$(grep -cE '^:::(tip|note|warning|info|danger|caution)' "$file" 2>/dev/null) || admonition_count=0
    if [ "$admonition_count" -lt 2 ]; then
        echo "  WARNING: $(basename "$file") has only $admonition_count admonition(s)"
        BLOG_ADMONITION_ISSUES=$((BLOG_ADMONITION_ISSUES + 1))
    fi
done
if [ "$BLOG_ADMONITION_ISSUES" -eq 0 ]; then
    pass_test "All blog posts have 2+ admonitions"
else
    fail_test "Found $BLOG_ADMONITION_ISSUES blog post(s) without admonitions" "Add :::tip, :::note, or :::warning admonitions to blog posts"
fi

# Summary
echo ""
echo "========================================"
echo "Test Summary:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed. Please fix the issues above."
    exit 1
fi
