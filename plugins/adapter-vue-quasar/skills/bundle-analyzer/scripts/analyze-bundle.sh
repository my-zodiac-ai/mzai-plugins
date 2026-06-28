#!/usr/bin/env bash
# Bundle size extraction script for My Zodiac AI
# Usage: bash analyze-bundle.sh <mode>
#   mode: compare  — git stash, build baseline, restore, build current, output both JSONs
#         snapshot — build current only
#         baseline — compare current build against front/bundle-baseline.json

set -euo pipefail

MODE="${1:-snapshot}"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FRONT_DIR="$PROJECT_ROOT/front"
OUTPUT_DIR="$FRONT_DIR/.bundle-analysis"

mkdir -p "$OUTPUT_DIR"

# ─── Helpers ───────────────────────────────────────────────

get_git_ref() {
  git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

get_git_message() {
  git -C "$PROJECT_ROOT" log -1 --pretty=%s 2>/dev/null | head -c 100 | tr "'" '"' || echo "unknown"
}

build_frontend() {
  echo "⏳ Building frontend (this takes 1-3 minutes)..."
  cd "$FRONT_DIR"
  pnpm build 2>&1 | tail -5
  echo "✅ Build complete"
  cd "$PROJECT_ROOT"
}

extract_sizes() {
  local output_file="$1"
  local label="$2"
  local ref message

  ref=$(get_git_ref)
  message=$(get_git_message)

  echo "📊 Extracting chunk sizes ($label)..."

  # Use Node.js to extract sizes and generate JSON
  node -e "
    const fs = require('fs');
    const path = require('path');
    const zlib = require('zlib');

    const distDir = '$FRONT_DIR/dist';
    const jsDir = path.join(distDir, 'js');
    const assetsDir = path.join(distDir, 'assets');

    const chunks = [];
    let totalRaw = 0;
    let totalGzip = 0;

    function processFile(filePath, category) {
      const stat = fs.statSync(filePath);
      const content = fs.readFileSync(filePath);
      const gzipSize = zlib.gzipSync(content).length;
      const name = path.basename(filePath).replace(/-[a-zA-Z0-9]+\.(js|css)$/, '');
      // Extract chunk name from filename pattern: chunkName-hash.ext
      const chunkName = path.basename(filePath).replace(/-[a-zA-Z0-9]{8,}\.(js|css)(\.map)?$/, '');

      totalRaw += stat.size;
      totalGzip += gzipSize;

      chunks.push({
        name: chunkName || path.basename(filePath),
        file: path.relative(distDir, filePath),
        raw: stat.size,
        gzip: gzipSize,
        category: category,
      });
    }

    // Process JS files
    if (fs.existsSync(jsDir)) {
      fs.readdirSync(jsDir)
        .filter(f => f.endsWith('.js') && !f.endsWith('.map'))
        .forEach(f => processFile(path.join(jsDir, f), 'js'));
    }

    // Process CSS files in assets/
    if (fs.existsSync(assetsDir)) {
      fs.readdirSync(assetsDir)
        .filter(f => f.endsWith('.css') && !f.endsWith('.map'))
        .forEach(f => processFile(path.join(assetsDir, f), 'css'));
    }

    // Also check root dist for any JS/CSS not in subdirs
    fs.readdirSync(distDir)
      .filter(f => (f.endsWith('.js') || f.endsWith('.css')) && !f.endsWith('.map'))
      .forEach(f => processFile(path.join(distDir, f), 'root'));

    // Sort by gzip size descending
    chunks.sort((a, b) => b.gzip - a.gzip);

    const result = {
      timestamp: new Date().toISOString(),
      git_ref: '$ref',
      git_message: '$message'.substring(0, 100),
      total_raw: totalRaw,
      total_gzip: totalGzip,
      chunk_count: chunks.length,
      chunks: chunks,
    };

    fs.writeFileSync('$output_file', JSON.stringify(result, null, 2));
    console.log('  Total raw: ' + (totalRaw / 1024).toFixed(1) + ' KB');
    console.log('  Total gzip: ' + (totalGzip / 1024).toFixed(1) + ' KB');
    console.log('  Chunks: ' + chunks.length);
  "

  echo "  → Saved to $output_file"
}

# ─── Main ──────────────────────────────────────────────────

case "$MODE" in
  compare)
    echo "🔄 Mode: before/after comparison"
    echo ""

    # Check if there are changes to stash
    HAS_CHANGES=false
    if ! git -C "$PROJECT_ROOT" diff --quiet 2>/dev/null || \
       ! git -C "$PROJECT_ROOT" diff --cached --quiet 2>/dev/null; then
      HAS_CHANGES=true
    fi

    if [ "$HAS_CHANGES" = true ]; then
      echo "📦 Stashing current changes..."
      git -C "$PROJECT_ROOT" stash push -m "bundle-analyzer-temp" --include-untracked

      # Build baseline (before changes)
      echo ""
      echo "━━━ BEFORE (baseline) ━━━"
      build_frontend
      extract_sizes "$OUTPUT_DIR/before.json" "before"

      # Restore changes
      echo ""
      echo "📦 Restoring your changes..."
      git -C "$PROJECT_ROOT" stash pop
    else
      echo "ℹ️  No uncommitted changes found. Comparing HEAD vs HEAD~1..."

      # Build current first (it's what we have)
      echo ""
      echo "━━━ AFTER (current HEAD) ━━━"
      build_frontend
      extract_sizes "$OUTPUT_DIR/after.json" "after (HEAD)"

      # Checkout previous commit for baseline
      CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current)
      echo ""
      echo "📦 Checking out HEAD~1 for baseline..."
      git -C "$PROJECT_ROOT" checkout HEAD~1 --quiet

      echo "━━━ BEFORE (HEAD~1) ━━━"
      build_frontend
      extract_sizes "$OUTPUT_DIR/before.json" "before (HEAD~1)"

      echo ""
      echo "📦 Returning to $CURRENT_BRANCH..."
      git -C "$PROJECT_ROOT" checkout "$CURRENT_BRANCH" --quiet

      echo ""
      echo "✅ Comparison ready!"
      echo "   Before: $OUTPUT_DIR/before.json"
      echo "   After:  $OUTPUT_DIR/after.json"
      exit 0
    fi

    # Build current (after changes)
    echo ""
    echo "━━━ AFTER (with changes) ━━━"
    build_frontend
    extract_sizes "$OUTPUT_DIR/after.json" "after"

    echo ""
    echo "✅ Comparison ready!"
    echo "   Before: $OUTPUT_DIR/before.json"
    echo "   After:  $OUTPUT_DIR/after.json"
    ;;

  snapshot)
    echo "📸 Mode: current snapshot"
    echo ""
    build_frontend
    extract_sizes "$OUTPUT_DIR/after.json" "current"
    echo ""
    echo "✅ Snapshot ready: $OUTPUT_DIR/after.json"
    ;;

  baseline)
    echo "📏 Mode: compare against baseline"
    echo ""

    BASELINE="$FRONT_DIR/bundle-baseline.json"
    if [ ! -f "$BASELINE" ]; then
      echo "⚠️  No baseline found at $BASELINE"
      echo "   Run in 'snapshot' mode first, then copy after.json to bundle-baseline.json"
      exit 1
    fi

    cp "$BASELINE" "$OUTPUT_DIR/before.json"
    build_frontend
    extract_sizes "$OUTPUT_DIR/after.json" "current"

    echo ""
    echo "✅ Comparison ready (current vs baseline)!"
    echo "   Baseline: $OUTPUT_DIR/before.json"
    echo "   Current:  $OUTPUT_DIR/after.json"
    ;;

  *)
    echo "❌ Unknown mode: $MODE"
    echo "   Usage: analyze-bundle.sh <compare|snapshot|baseline>"
    exit 1
    ;;
esac
