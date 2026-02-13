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
    ((TESTS_PASSED++))
}

fail_test() {
    echo "✗ $1"
    echo "  Error: $2"
    ((TESTS_FAILED++))
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
    grep -oP '\[.*?\]\(\K[^)]+' "$file" 2>/dev/null | while read -r link; do
        # Skip external links (http/https)
        if [[ "$link" =~ ^https?:// ]]; then
            continue
        fi

        # Skip anchor-only links
        if [[ "$link" =~ ^# ]]; then
            continue
        fi

        # Check if relative path exists
        link_path=$(dirname "$file")/"$link"
        if [[ ! -f "$link_path" ]] && [[ ! -d "$link_path" ]]; then
            echo "  Broken link in $file: $link"
            ((BROKEN_LINKS++))
        fi
    done
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
        ((FORMATTING_ISSUES++))
    fi

    # Check for frontmatter
    if ! head -1 "$file" | grep -q "^---$"; then
        echo "  Missing frontmatter in: $file"
        ((FORMATTING_ISSUES++))
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
TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX" docs/ --include="*.md" 2>/dev/null | wc -l)

if [ "$TODO_COUNT" -eq 0 ]; then
    pass_test "No unresolved TODO markers"
else
    echo "  Found $TODO_COUNT TODO/FIXME marker(s) in documentation"
    grep -r "TODO\|FIXME\|XXX" docs/ --include="*.md" 2>/dev/null | head -5
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
        ((MISSING_DOCS++))
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
        ((LARGE_FILES++))
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
