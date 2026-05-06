#!/usr/bin/env node
/**
 * Bundle comparison and report generator for My Zodiac AI.
 *
 * Usage:
 *   node compare-bundles.js --after after.json [--before before.json] [--budgets .lighthouserc.js] [--output report.md]
 *
 * Produces a Markdown report with:
 *   - Summary table (total raw/gzip, chunk count)
 *   - Per-chunk delta table (sorted by absolute gzip delta)
 *   - Budget compliance check
 *   - Top-N largest chunks
 */

const fs = require('fs');
const path = require('path');

// ─── Parse CLI args ─────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, '');
    opts[key] = args[i + 1];
  }
  return opts;
}

const opts = parseArgs();

if (!opts.after) {
  console.error('Usage: compare-bundles.js --after <path> [--before <path>] [--budgets <path>] [--output <path>]');
  process.exit(1);
}

// ─── Load data ──────────────────────────────────────────────

const after = JSON.parse(fs.readFileSync(opts.after, 'utf8'));
const before = opts.before && fs.existsSync(opts.before)
  ? JSON.parse(fs.readFileSync(opts.before, 'utf8'))
  : null;

// ─── Budget parsing ─────────────────────────────────────────

const budgets = { jsPerFile: 250 * 1024, totalJs: 1000 * 1024 };
const featureBudgets = {
  'cosmic-weather-v3': 150 * 1024, // gzip target from vite.config.ts
};

if (opts.budgets && fs.existsSync(opts.budgets)) {
  try {
    const content = fs.readFileSync(opts.budgets, 'utf8');
    // Extract maxSize for JS from lighthouse budgets
    const jsMatch = content.match(/path:\s*['"]dist\/\*\*\/\*\.js['"][\s\S]*?maxSize:\s*['"](\d+)KB['"]/);
    if (jsMatch) budgets.jsPerFile = parseInt(jsMatch[1]) * 1024;
    const totalMatch = content.match(/resource-summary:total:size.*?maxNumericValue:\s*(\d+)/);
    if (totalMatch) budgets.totalJs = parseInt(totalMatch[1]);
  } catch (e) {
    // Silently fall back to defaults
  }
}

// ─── Helpers ────────────────────────────────────────────────

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  const kb = bytes / 1024;
  if (kb < 1024) return `${kb.toFixed(1)} KB`;
  return `${(kb / 1024).toFixed(2)} MB`;
}

function formatDelta(before, after) {
  if (before === 0 || before === null || before === undefined) return '✨ new';
  const delta = after - before;
  const pct = ((delta / before) * 100).toFixed(1);
  const sign = delta >= 0 ? '+' : '';
  const emoji = delta > 0 ? '🔺' : delta < 0 ? '🟢' : '';
  return `${sign}${formatBytes(Math.abs(delta))} (${sign}${pct}%) ${emoji}`;
}

function statusEmoji(gzipSize, chunkName) {
  // Check feature-specific budget first
  if (featureBudgets[chunkName] && gzipSize > featureBudgets[chunkName]) {
    return '🔴';
  }
  // Check per-file budget
  if (gzipSize > budgets.jsPerFile) return '🔴';
  if (gzipSize > budgets.jsPerFile * 0.8) return '🟡'; // Warning at 80%
  return '✅';
}

// ─── Build chunk map for "before" ───────────────────────────

const beforeMap = {};
if (before) {
  for (const chunk of before.chunks) {
    beforeMap[chunk.name] = chunk;
  }
}

// ─── Generate report ────────────────────────────────────────

const lines = [];
const now = new Date().toISOString().split('T')[0];

lines.push(`# Bundle Analysis Report`);
lines.push(`> Generated: ${now} | Git: \`${after.git_ref}\` (${after.git_message})`);
if (before) {
  lines.push(`> Baseline: \`${before.git_ref}\` (${before.git_message})`);
}
lines.push('');

// ─── Summary ────────────────────────────────────────────────

lines.push('## Summary');
lines.push('');

if (before) {
  lines.push('| Metric | Before | After | Delta |');
  lines.push('|--------|--------|-------|-------|');
  lines.push(`| Total (raw) | ${formatBytes(before.total_raw)} | ${formatBytes(after.total_raw)} | ${formatDelta(before.total_raw, after.total_raw)} |`);
  lines.push(`| Total (gzip) | ${formatBytes(before.total_gzip)} | ${formatBytes(after.total_gzip)} | ${formatDelta(before.total_gzip, after.total_gzip)} |`);
  lines.push(`| Chunk count | ${before.chunk_count} | ${after.chunk_count} | ${after.chunk_count - before.chunk_count === 0 ? '0' : (after.chunk_count > before.chunk_count ? '+' : '') + (after.chunk_count - before.chunk_count)} |`);
} else {
  lines.push('| Metric | Value |');
  lines.push('|--------|-------|');
  lines.push(`| Total (raw) | ${formatBytes(after.total_raw)} |`);
  lines.push(`| Total (gzip) | ${formatBytes(after.total_gzip)} |`);
  lines.push(`| Chunk count | ${after.chunk_count} |`);
}

lines.push('');

// ─── Chunk Details ──────────────────────────────────────────

lines.push('## Chunk Details');
lines.push('');

// Sort chunks: biggest gzip delta first (if comparing), else by gzip size
const sortedChunks = [...after.chunks];
if (before) {
  sortedChunks.sort((a, b) => {
    const deltaA = Math.abs(a.gzip - (beforeMap[a.name]?.gzip || 0));
    const deltaB = Math.abs(b.gzip - (beforeMap[b.name]?.gzip || 0));
    return deltaB - deltaA;
  });
}

if (before) {
  lines.push('| Chunk | Category | Before (gzip) | After (gzip) | Delta | Status |');
  lines.push('|-------|----------|---------------|--------------|-------|--------|');
  for (const chunk of sortedChunks) {
    const prev = beforeMap[chunk.name];
    const prevGzip = prev ? formatBytes(prev.gzip) : '—';
    const delta = prev ? formatDelta(prev.gzip, chunk.gzip) : '✨ new';
    const status = statusEmoji(chunk.gzip, chunk.name);
    lines.push(`| \`${chunk.name}\` | ${chunk.category} | ${prevGzip} | ${formatBytes(chunk.gzip)} | ${delta} | ${status} |`);
  }

  // Check for removed chunks
  for (const name of Object.keys(beforeMap)) {
    if (!after.chunks.find(c => c.name === name)) {
      const prev = beforeMap[name];
      lines.push(`| \`${name}\` | ${prev.category} | ${formatBytes(prev.gzip)} | — | 🗑️ removed | — |`);
    }
  }
} else {
  lines.push('| Chunk | Category | Raw | Gzip | % of Total | Status |');
  lines.push('|-------|----------|-----|------|------------|--------|');
  for (const chunk of sortedChunks) {
    const pct = ((chunk.gzip / after.total_gzip) * 100).toFixed(1);
    const status = statusEmoji(chunk.gzip, chunk.name);
    lines.push(`| \`${chunk.name}\` | ${chunk.category} | ${formatBytes(chunk.raw)} | ${formatBytes(chunk.gzip)} | ${pct}% | ${status} |`);
  }
}

lines.push('');

// ─── Budget Compliance ──────────────────────────────────────

lines.push('## Budget Compliance');
lines.push('');

const jsChunks = after.chunks.filter(c => c.category === 'js');
const totalJsGzip = jsChunks.reduce((sum, c) => sum + c.gzip, 0);

// Per-file budget
for (const chunk of jsChunks) {
  const featureBudget = featureBudgets[chunk.name];
  if (featureBudget) {
    const ok = chunk.gzip <= featureBudget;
    lines.push(`- ${ok ? '✅' : '🔴'} \`${chunk.name}\`: ${formatBytes(chunk.gzip)} gzip (feature budget: ${formatBytes(featureBudget)})${!ok ? ' **OVER BUDGET**' : ''}`);
  } else {
    const ok = chunk.gzip <= budgets.jsPerFile;
    if (!ok) {
      lines.push(`- 🔴 \`${chunk.name}\`: ${formatBytes(chunk.gzip)} gzip (budget: ${formatBytes(budgets.jsPerFile)}) **OVER BUDGET**`);
    }
  }
}

// Total budget
const totalOk = totalJsGzip <= budgets.totalJs;
lines.push(`- ${totalOk ? '✅' : '🔴'} Total JS: ${formatBytes(totalJsGzip)} gzip (budget: ${formatBytes(budgets.totalJs)})${!totalOk ? ' **OVER BUDGET**' : ''}`);

// Show all-clear if nothing is over budget
const overBudget = jsChunks.filter(c => {
  const fb = featureBudgets[c.name];
  return fb ? c.gzip > fb : c.gzip > budgets.jsPerFile;
});
if (overBudget.length === 0 && totalOk) {
  lines.push('');
  lines.push('All chunks within budget. ✅');
}

lines.push('');

// ─── Top 5 Largest Chunks ───────────────────────────────────

lines.push('## Top 5 Largest Chunks (gzip)');
lines.push('');

const top5 = [...after.chunks].sort((a, b) => b.gzip - a.gzip).slice(0, 5);
for (let i = 0; i < top5.length; i++) {
  const c = top5[i];
  const pct = ((c.gzip / after.total_gzip) * 100).toFixed(1);
  lines.push(`${i + 1}. \`${c.name}\` — ${formatBytes(c.gzip)} (${pct}% of total)`);
}

lines.push('');

// ─── Biggest Movers (comparison only) ───────────────────────

if (before) {
  lines.push('## Biggest Movers');
  lines.push('');

  const movers = after.chunks
    .filter(c => beforeMap[c.name])
    .map(c => ({
      name: c.name,
      delta: c.gzip - beforeMap[c.name].gzip,
      absDelta: Math.abs(c.gzip - beforeMap[c.name].gzip),
      pctDelta: ((c.gzip - beforeMap[c.name].gzip) / beforeMap[c.name].gzip * 100),
    }))
    .filter(m => m.absDelta > 1024) // Only show changes > 1KB
    .sort((a, b) => b.absDelta - a.absDelta)
    .slice(0, 5);

  if (movers.length === 0) {
    lines.push('No significant chunk size changes (>1KB).');
  } else {
    for (const m of movers) {
      const sign = m.delta >= 0 ? '+' : '';
      const emoji = m.delta > 0 ? '🔺' : '🟢';
      lines.push(`- ${emoji} \`${m.name}\`: ${sign}${formatBytes(Math.abs(m.delta))} (${sign}${m.pctDelta.toFixed(1)}%)`);
    }
  }

  lines.push('');
}

// ─── Placeholder sections for agent analysis ────────────────

lines.push('## Heavy Imports Analysis');
lines.push('');
lines.push('<!-- Agent: fill this section after investigating the largest/fastest-growing chunks -->');
lines.push('');

lines.push('## Recommendations');
lines.push('');
lines.push('<!-- Agent: fill this section with prioritized code-splitting and optimization suggestions -->');
lines.push('');

// ─── Write output ───────────────────────────────────────────

const report = lines.join('\n');

if (opts.output) {
  fs.mkdirSync(path.dirname(opts.output), { recursive: true });
  fs.writeFileSync(opts.output, report);
  console.log(`📝 Report written to ${opts.output}`);
} else {
  console.log(report);
}

// Also write a machine-readable summary for trend tracking
const summary = {
  timestamp: after.timestamp,
  git_ref: after.git_ref,
  git_message: after.git_message,
  total_raw: after.total_raw,
  total_gzip: after.total_gzip,
  chunk_count: after.chunk_count,
  top_chunks: top5.map(c => ({ name: c.name, gzip: c.gzip })),
  budget_violations: overBudget.map(c => c.name),
  delta: before ? {
    total_raw: after.total_raw - before.total_raw,
    total_gzip: after.total_gzip - before.total_gzip,
    pct_raw: ((after.total_raw - before.total_raw) / before.total_raw * 100).toFixed(1),
    pct_gzip: ((after.total_gzip - before.total_gzip) / before.total_gzip * 100).toFixed(1),
  } : null,
};

const summaryPath = opts.output
  ? opts.output.replace(/\.md$/, '-summary.json')
  : null;

if (summaryPath) {
  fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
  console.log(`📊 Summary JSON written to ${summaryPath}`);
}
