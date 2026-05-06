#!/usr/bin/env bash
# parse-lighthouse.sh — Extract scores and metrics from LHCI JSON reports
# Usage: ./parse-lighthouse.sh [path-to-.lighthouseci-dir]
#
# Outputs JSON summary to stdout with per-URL scores and metrics.

set -euo pipefail

LHCI_DIR="${1:-front/.lighthouseci}"

if [ ! -d "$LHCI_DIR" ]; then
  echo "Error: LHCI results directory not found: $LHCI_DIR" >&2
  exit 1
fi

# Find most recent batch of LHR files (within last 10 minutes)
RECENT_FILES=$(find "$LHCI_DIR" -name "lhr-*.json" -mmin -10 2>/dev/null | sort)

if [ -z "$RECENT_FILES" ]; then
  # Fallback: take the most recent files regardless of age
  RECENT_FILES=$(ls -t "$LHCI_DIR"/lhr-*.json 2>/dev/null | head -30)
fi

if [ -z "$RECENT_FILES" ]; then
  echo "Error: No LHR JSON files found in $LHCI_DIR" >&2
  exit 1
fi

echo "Found $(echo "$RECENT_FILES" | wc -l | tr -d ' ') report files" >&2

# Parse each file and output structured JSON
node -e "
const fs = require('fs');
const files = process.argv.slice(1);
const results = [];

for (const file of files) {
  try {
    const lhr = JSON.parse(fs.readFileSync(file, 'utf-8'));
    const url = new URL(lhr.requestedUrl || lhr.finalUrl);

    results.push({
      file: file.split('/').pop(),
      url: url.pathname,
      fetchTime: lhr.fetchTime,
      scores: {
        performance: lhr.categories?.performance?.score,
        accessibility: lhr.categories?.accessibility?.score,
        'best-practices': lhr.categories?.['best-practices']?.score,
        seo: lhr.categories?.seo?.score,
      },
      metrics: {
        fcp: lhr.audits?.['first-contentful-paint']?.numericValue,
        lcp: lhr.audits?.['largest-contentful-paint']?.numericValue,
        cls: lhr.audits?.['cumulative-layout-shift']?.numericValue,
        tbt: lhr.audits?.['total-blocking-time']?.numericValue,
        si: lhr.audits?.['speed-index']?.numericValue,
        tti: lhr.audits?.['interactive']?.numericValue,
      },
      resources: lhr.audits?.['resource-summary']?.details?.items || [],
      failingAudits: Object.entries(lhr.audits || {})
        .filter(([_, a]) => a.score !== null && a.score < 0.5)
        .map(([id, a]) => ({ id, score: a.score, title: a.title, description: a.description?.substring(0, 200) }))
        .slice(0, 20),
    });
  } catch (e) {
    console.error('Failed to parse ' + file + ': ' + e.message);
  }
}

// Group by URL and compute medians
const byUrl = {};
for (const r of results) {
  if (!byUrl[r.url]) byUrl[r.url] = [];
  byUrl[r.url].push(r);
}

const median = arr => {
  const sorted = arr.filter(x => x != null).sort((a, b) => a - b);
  if (!sorted.length) return null;
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
};

const summary = Object.entries(byUrl).map(([url, runs]) => ({
  url,
  runs: runs.length,
  scores: {
    performance: median(runs.map(r => r.scores.performance)),
    accessibility: median(runs.map(r => r.scores.accessibility)),
    'best-practices': median(runs.map(r => r.scores['best-practices'])),
    seo: median(runs.map(r => r.scores.seo)),
  },
  metrics: {
    fcp: median(runs.map(r => r.metrics.fcp)),
    lcp: median(runs.map(r => r.metrics.lcp)),
    cls: median(runs.map(r => r.metrics.cls)),
    tbt: median(runs.map(r => r.metrics.tbt)),
    si: median(runs.map(r => r.metrics.si)),
    tti: median(runs.map(r => r.metrics.tti)),
  },
  failingAudits: runs[0]?.failingAudits || [],
}));

console.log(JSON.stringify({ totalFiles: files.length, urls: summary }, null, 2));
" $RECENT_FILES
