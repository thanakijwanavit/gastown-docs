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
