#!/bin/bash

# QA Report Generator Script
# Generates comprehensive QA report after all iterations complete

set -euo pipefail

FEATURE_ID="${1:-}"
FINAL_STATUS="${2:-}"
ITERATION_COUNT="${3:-}"

PROJECT_ROOT="/Users/valentinyakovlev/projects/my_zodiac_ai"
QA_DIR="$PROJECT_ROOT/.specify/qa"
ITERATION_DIR="$QA_DIR/iterations/$FEATURE_ID"
REPORT_DIR="$QA_DIR/reports"
REPORT_FILE="$REPORT_DIR/$FEATURE_ID-qa-report.md"

# Create secure temp directory
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/qa-report-XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[REPORT]${NC} $1"; }
log_success() { echo -e "${GREEN}[DONE]${NC} $1"; }

# Generate report header
generate_header() {
    local start_time=$(head -1 "$ITERATION_DIR/iteration-001.md" 2>/dev/null | grep "Timestamp:" | cut -d: -f2- | xargs || echo "Unknown")
    local end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$REPORT_FILE" << EOF
---
feature-id: $FEATURE_ID
final-status: $FINAL_STATUS
iterations: $ITERATION_COUNT
start-time: $start_time
end-time: $end_time
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

# QA Report: $FEATURE_ID

## Summary

Feature validation completed after **$ITERATION_COUNT iterations**.

**Final Status:** $FINAL_STATUS

**Timeline:**
- Started: $start_time
- Completed: $end_time
- Duration: Calculated below

EOF
}

# Generate sign-off section
generate_signoff() {
    echo "" >> "$REPORT_FILE"
    echo "## Sign-off" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ "$FINAL_STATUS" == "PASS" ]; then
        echo "✅ **QA APPROVED**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Feature $FEATURE_ID has passed all validations and is ready for deployment." >> "$REPORT_FILE"
    elif [ "$FINAL_STATUS" == "MANUAL_REVIEW" ]; then
        echo "⚠️ **MANUAL REVIEW REQUIRED**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Feature $FEATURE_ID has auto-fixable issues resolved but requires manual review for items listed above." >> "$REPORT_FILE"
    else
        echo "❌ **QA FAILED**" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "Feature $FEATURE_ID has critical issues that could not be resolved." >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Report generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$REPORT_FILE"
    echo "QA Check complete." >> "$REPORT_FILE"
}

# Main execution
main() {
    # Sanitize inputs
    if [[ ! "$FEATURE_ID" =~ ^[a-z0-9-]+$ ]]; then
        echo "Invalid feature ID format"
        exit 1
    fi

    if [[ ! "$ITERATION_COUNT" =~ ^[0-9]+$ ]] || [ "$ITERATION_COUNT" -lt 1 ] || [ "$ITERATION_COUNT" -gt 100 ]; then
        echo "Invalid iteration count"
        exit 1
    fi

    if [[ ! "$FINAL_STATUS" =~ ^(PASS|MANUAL_REVIEW|FAIL)$ ]]; then
        echo "Invalid final status. Must be PASS, MANUAL_REVIEW, or FAIL"
        exit 1
    fi

    log_info "Generating QA report for $FEATURE_ID..."

    # Ensure directories exist
    mkdir -p "$REPORT_DIR"

    # Generate all sections
    generate_header
    generate_signoff

    log_success "QA report generated: $REPORT_FILE"
}

main