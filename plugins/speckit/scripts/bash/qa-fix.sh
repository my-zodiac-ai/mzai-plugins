#!/bin/bash

# QA Fix Dispatcher Script
# Analyzes validation failures and applies appropriate auto-fixes

set -euo pipefail

FEATURE_ID="${1:-}"
ITERATION="${2:-}"
PROJECT_ROOT="/Users/valentinyakovlev/projects/my_zodiac_ai"
QA_DIR="$PROJECT_ROOT/.specify/qa"
ITERATION_DIR="$QA_DIR/iterations/$FEATURE_ID"

# Create secure temp directory
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/qa-fix-XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[FIX]${NC} $1"; }
log_success() { echo -e "${GREEN}[FIXED]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Initialize fix log
init_fix_log() {
    mkdir -p "$ITERATION_DIR"
    FIX_LOG="$ITERATION_DIR/iteration-$ITERATION-fixes.md"

    cat > "$FIX_LOG" << EOF
# Auto-Fix Log - Iteration $ITERATION

Feature: $FEATURE_ID
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Fixes Applied

EOF
}

# Fix ESLint auto-fixable issues
fix_eslint() {
    log_info "Attempting ESLint auto-fix..."

    local eslint_json="$TMP_DIR/eslint.json"

    if [ ! -f "$eslint_json" ]; then
        log_warn "ESLint results not found, skipping"
        return 0
    fi

    # Count auto-fixable errors
    local fixable=$(jq '[.[].messages[] | select(.fix != null)] | length' "$eslint_json" 2>/dev/null || echo "0")

    if [ "$fixable" -gt 0 ]; then
        cd "$PROJECT_ROOT/back"
        npm run lint -- --fix 2>&1 | tee -a "$FIX_LOG"
        log_success "ESLint auto-fixed $fixable issues"
        echo "- ESLint: Auto-fixed $fixable issues" >> "$FIX_LOG"
    else
        log_info "No auto-fixable ESLint issues"
    fi
}

# Generate fix summary
generate_fix_summary() {
    log_info "Generating fix summary..."

    local fix_count=$(grep -c "^- " "$FIX_LOG" 2>/dev/null || echo "0")

    echo "" >> "$FIX_LOG"
    echo "## Summary" >> "$FIX_LOG"
    echo "Total fixes applied: $fix_count" >> "$FIX_LOG"
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$FIX_LOG"

    if [ $fix_count -eq 0 ]; then
        echo "No auto-fixes applied in this iteration." >> "$FIX_LOG"
        log_warn "No fixes applied - may need manual intervention"
    else
        log_success "Applied $fix_count fixes, check $FIX_LOG"
    fi
}

# Main execution
main() {
    if [ -z "$FEATURE_ID" ] || [ -z "$ITERATION" ]; then
        log_error "Feature ID and iteration number required"
        echo "Usage: $0 <feature-id> <iteration-number>"
        exit 1
    fi

    # Validate feature ID format
    if [[ ! "$FEATURE_ID" =~ ^[a-z0-9-]+$ ]]; then
        log_error "Invalid feature ID format"
        exit 1
    fi

    # Validate iteration is a number and within bounds
    if [[ ! "$ITERATION" =~ ^[0-9]+$ ]] || [ "$ITERATION" -lt 1 ] || [ "$ITERATION" -gt 100 ]; then
        log_error "Invalid iteration number. Must be 1-100."
        exit 1
    fi

    log_info "Starting auto-fix for $FEATURE_ID (iteration $ITERATION)"

    init_fix_log

    # Run fixes in priority order
    fix_eslint

    # Generate summary
    generate_fix_summary

    log_info "Auto-fix complete"
}

main