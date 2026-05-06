#!/usr/bin/env python3
"""
RUM Analytics HTML Report Generator
Reads a JSON data file and produces an interactive HTML report with
CWV metrics, device segmentation, synthetic vs real comparison, and fix suggestions.
"""

import json
import sys
import os
import argparse
from datetime import datetime


# Google CWV thresholds
THRESHOLDS = {
    "LCP": {"good": 2500, "needs_improvement": 4000, "unit": "ms"},
    "CLS": {"good": 0.1, "needs_improvement": 0.25, "unit": ""},
    "INP": {"good": 200, "needs_improvement": 500, "unit": "ms"},
    "FCP": {"good": 1800, "needs_improvement": 3000, "unit": "ms"},
    "TTFB": {"good": 800, "needs_improvement": 1800, "unit": "ms"},
}


def classify(metric: str, value: float) -> str:
    t = THRESHOLDS.get(metric)
    if not t:
        return "unknown"
    if value <= t["good"]:
        return "good"
    if value <= t["needs_improvement"]:
        return "needs-improvement"
    return "poor"


def fmt_value(metric: str, value: float) -> str:
    t = THRESHOLDS.get(metric, {})
    unit = t.get("unit", "")
    if unit == "ms":
        if value >= 1000:
            return f"{value/1000:.2f}s"
        return f"{value:.0f}ms"
    return f"{value:.3f}" if metric == "CLS" else f"{value:.1f}"


def generate_html(data: dict) -> str:
    generated = data.get("generated_at", datetime.now().isoformat())
    window = data.get("time_window", "7 days")

    # Extract overall metrics from NewRelic
    nr = data.get("newrelic", {}).get("overall", {})
    lh = data.get("lighthouse", {})
    analysis = data.get("analysis", {})

    # Build metrics rows
    metrics_map = {
        "LCP": {"nr_key": "LCP_p75", "lh_key": "lcp_ms"},
        "CLS": {"nr_key": "CLS_p75", "lh_key": "cls"},
        "INP": {"nr_key": "INP_p75", "lh_key": None},
        "FCP": {"nr_key": "FCP_p75", "lh_key": "fcp_ms"},
        "TTFB": {"nr_key": "TTFB_p75", "lh_key": None},
    }

    cwv_rows = ""
    overall_verdict = "good"
    for name, keys in metrics_map.items():
        rum_val = nr.get(keys["nr_key"])
        lh_val = lh.get(keys["lh_key"]) if keys["lh_key"] else None

        if rum_val is not None:
            cls_ = classify(name, rum_val)
            if cls_ == "poor":
                overall_verdict = "poor"
            elif cls_ == "needs-improvement" and overall_verdict != "poor":
                overall_verdict = "needs-improvement"

            gap = ""
            if rum_val is not None and lh_val is not None and lh_val > 0:
                gap_pct = (rum_val - lh_val) / lh_val * 100
                gap_cls = "gap-high" if gap_pct > 50 else "gap-med" if gap_pct > 20 else "gap-low"
                gap = f'<span class="{gap_cls}">{gap_pct:+.0f}%</span>'

            cwv_rows += f"""
            <tr>
              <td><strong>{name}</strong></td>
              <td class="{cls_}">{fmt_value(name, rum_val)}</td>
              <td>{fmt_value(name, lh_val) if lh_val is not None else '—'}</td>
              <td>{gap or '—'}</td>
              <td>{nr.get('samples', '—')}</td>
            </tr>"""

    # Device segmentation rows
    # Keys: deviceType = userAgentOS (e.g. "Android", "iPhone", "Windows")
    #       operatingSystem = userAgentName (e.g. "Chrome", "Safari", "Firefox")
    device_rows = ""
    for seg in data.get("newrelic", {}).get("by_device_os", []):
        device_rows += f"""
            <tr>
              <td>{seg.get('deviceType', '—')}</td>
              <td>{seg.get('operatingSystem', '—')}</td>
              <td class="{classify('LCP', seg.get('LCP_p75', 0))}">{fmt_value('LCP', seg.get('LCP_p75', 0))}</td>
              <td class="{classify('CLS', seg.get('CLS_p75', 0))}">{fmt_value('CLS', seg.get('CLS_p75', 0))}</td>
              <td class="{classify('INP', seg.get('INP_p75', 0))}">{fmt_value('INP', seg.get('INP_p75', 0))}</td>
              <td>{seg.get('samples', '—')}</td>
            </tr>"""

    # Country breakdown rows
    country_rows = ""
    for c in data.get("newrelic", {}).get("by_country", []):
        country_rows += f"""
            <tr>
              <td><strong>{c.get('countryCode', '—')}</strong></td>
              <td class="{classify('LCP', c.get('LCP_p75', 0))}">{fmt_value('LCP', c.get('LCP_p75', 0))}</td>
              <td class="{classify('CLS', c.get('CLS_p75', 0))}">{fmt_value('CLS', c.get('CLS_p75', 0))}</td>
              <td class="{classify('INP', c.get('INP_p75', 0))}">{fmt_value('INP', c.get('INP_p75', 0))}</td>
              <td>{c.get('samples', '—')}</td>
            </tr>"""

    # Page breakdown rows
    page_rows = ""
    for pg in data.get("newrelic", {}).get("by_page", []):
        page_rows += f"""
            <tr>
              <td title="{pg.get('pageUrl', '')}">{pg.get('pageUrl', '—')[:60]}</td>
              <td class="{classify('LCP', pg.get('LCP_p75', 0))}">{fmt_value('LCP', pg.get('LCP_p75', 0))}</td>
              <td class="{classify('CLS', pg.get('CLS_p75', 0))}">{fmt_value('CLS', pg.get('CLS_p75', 0))}</td>
              <td class="{classify('INP', pg.get('INP_p75', 0))}">{fmt_value('INP', pg.get('INP_p75', 0))}</td>
              <td>{pg.get('samples', '—')}</td>
            </tr>"""

    # Fix suggestions
    fixes_html = ""
    for fix in analysis.get("fixes", []):
        priority_cls = "fix-critical" if fix.get("priority") == "critical" else \
                       "fix-high" if fix.get("priority") == "high" else "fix-medium"
        fixes_html += f"""
        <div class="fix-card {priority_cls}">
          <div class="fix-header">
            <span class="fix-priority">{fix.get('priority', 'medium').upper()}</span>
            <span class="fix-metric">{fix.get('metric', '')}</span>
            <span class="fix-impact">{fix.get('expected_impact', '')}</span>
          </div>
          <p>{fix.get('description', '')}</p>
          {'<pre><code>' + fix.get('code_snippet', '') + '</code></pre>' if fix.get('code_snippet') else ''}
          <small>{fix.get('file_path', '')}</small>
        </div>"""

    # Timeseries data for sparklines
    ts_data = json.dumps(data.get("newrelic", {}).get("timeseries", []))

    verdict_emoji = {"good": "green", "needs-improvement": "orange", "poor": "red"}[overall_verdict]

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RUM Analytics Report — My Zodiac AI</title>
<style>
  :root {{
    --good: #0cce6b;
    --needs-improvement: #ffa400;
    --poor: #ff4e42;
    --bg: #0f1117;
    --surface: #1a1d27;
    --text: #e2e8f0;
    --text-dim: #94a3b8;
    --border: #2d3348;
    --accent: #818cf8;
  }}
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: 'Inter', -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; line-height: 1.6; }}
  .container {{ max-width: 1200px; margin: 0 auto; }}
  h1 {{ font-size: 1.75rem; margin-bottom: 0.5rem; }}
  h2 {{ font-size: 1.25rem; margin: 2rem 0 1rem; color: var(--accent); border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; }}
  .meta {{ color: var(--text-dim); font-size: 0.85rem; margin-bottom: 2rem; }}

  .verdict {{ display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.5rem 1rem;
    border-radius: 8px; font-weight: 600; font-size: 1.1rem; margin: 1rem 0; }}
  .verdict.good {{ background: rgba(12,206,107,0.15); color: var(--good); border: 1px solid rgba(12,206,107,0.3); }}
  .verdict.needs-improvement {{ background: rgba(255,164,0,0.15); color: var(--needs-improvement); border: 1px solid rgba(255,164,0,0.3); }}
  .verdict.poor {{ background: rgba(255,78,66,0.15); color: var(--poor); border: 1px solid rgba(255,78,66,0.3); }}

  table {{ width: 100%; border-collapse: collapse; background: var(--surface); border-radius: 8px; overflow: hidden; margin-bottom: 1rem; }}
  th {{ background: var(--border); padding: 0.75rem 1rem; text-align: left; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.05em; }}
  td {{ padding: 0.6rem 1rem; border-bottom: 1px solid var(--border); font-size: 0.9rem; }}
  tr:last-child td {{ border-bottom: none; }}
  tr:hover {{ background: rgba(129,140,248,0.05); }}

  .good {{ color: var(--good); font-weight: 600; }}
  .needs-improvement {{ color: var(--needs-improvement); font-weight: 600; }}
  .poor {{ color: var(--poor); font-weight: 600; }}

  .gap-high {{ color: var(--poor); font-weight: 600; }}
  .gap-med {{ color: var(--needs-improvement); }}
  .gap-low {{ color: var(--text-dim); }}

  .fix-card {{ background: var(--surface); border-radius: 8px; padding: 1rem; margin-bottom: 0.75rem; border-left: 3px solid var(--border); }}
  .fix-critical {{ border-left-color: var(--poor); }}
  .fix-high {{ border-left-color: var(--needs-improvement); }}
  .fix-medium {{ border-left-color: var(--accent); }}
  .fix-header {{ display: flex; gap: 0.75rem; align-items: center; margin-bottom: 0.5rem; }}
  .fix-priority {{ font-size: 0.7rem; font-weight: 700; padding: 2px 8px; border-radius: 4px; background: rgba(255,255,255,0.08); }}
  .fix-metric {{ color: var(--accent); font-weight: 600; }}
  .fix-impact {{ color: var(--text-dim); font-size: 0.85rem; }}
  .fix-card p {{ margin-bottom: 0.5rem; }}
  .fix-card pre {{ background: var(--bg); padding: 0.75rem; border-radius: 4px; overflow-x: auto; font-size: 0.8rem; margin-bottom: 0.5rem; }}
  .fix-card small {{ color: var(--text-dim); font-family: monospace; font-size: 0.8rem; }}

  canvas {{ max-height: 200px; margin: 1rem 0; }}
  .chart-container {{ background: var(--surface); border-radius: 8px; padding: 1rem; }}
  .two-col {{ display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }}
  @media (max-width: 768px) {{ .two-col {{ grid-template-columns: 1fr; }} }}
</style>
</head>
<body>
<div class="container">
  <h1>RUM Analytics Report</h1>
  <div class="meta">My Zodiac AI | Window: {window} | Generated: {generated}</div>

  <div class="verdict {overall_verdict}">
    Overall CWV: {overall_verdict.replace('-', ' ').upper()}
  </div>

  <h2>Core Web Vitals — Synthetic vs Real</h2>
  <table>
    <thead>
      <tr><th>Metric</th><th>RUM p75</th><th>Lighthouse</th><th>Gap</th><th>Samples</th></tr>
    </thead>
    <tbody>{cwv_rows or '<tr><td colspan="5">No data available</td></tr>'}</tbody>
  </table>

  <h2>7-Day CWV Trend</h2>
  <div class="two-col">
    <div class="chart-container"><canvas id="lcpChart"></canvas></div>
    <div class="chart-container"><canvas id="clsChart"></canvas></div>
  </div>

  <h2>OS / Browser Segmentation</h2>
  <table>
    <thead>
      <tr><th>OS</th><th>Browser</th><th>LCP p75</th><th>CLS p75</th><th>INP p75</th><th>Samples</th></tr>
    </thead>
    <tbody>{device_rows or '<tr><td colspan="6">No segmentation data</td></tr>'}</tbody>
  </table>

  {'<h2>Geographic Breakdown</h2><table><thead><tr><th>Country</th><th>LCP p75</th><th>CLS p75</th><th>INP p75</th><th>Samples</th></tr></thead><tbody>' + country_rows + '</tbody></table>' if country_rows else ''}

  <h2>Page Breakdown</h2>
  <table>
    <thead>
      <tr><th>Page</th><th>LCP p75</th><th>CLS p75</th><th>INP p75</th><th>Samples</th></tr>
    </thead>
    <tbody>{page_rows or '<tr><td colspan="5">No page data</td></tr>'}</tbody>
  </table>

  <h2>Fix Recommendations</h2>
  {fixes_html or '<p style="color:var(--text-dim)">All metrics within thresholds. No fixes needed.</p>'}

  <h2>Data Quality</h2>
  <table>
    <tr><td>NewRelic samples</td><td>{nr.get('samples', 'N/A')}</td></tr>
    <tr><td>PostHog events</td><td>{sum(p.get('samples', 0) for p in data.get('posthog', {{}}).get('by_page', [])) if data.get('posthog') else 'N/A'}</td></tr>
    <tr><td>Lighthouse baseline</td><td>{'Present' if lh else 'Missing'}</td></tr>
  </table>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script>
const tsData = {ts_data};
if (tsData.length > 0) {{
  const labels = tsData.map(d => d.date || d.beginTimeSeconds || '');
  const lcpValues = tsData.map(d => d.LCP_p75 || 0);
  const clsValues = tsData.map(d => d.CLS_p75 || 0);

  const chartOpts = (label, data, color, thresholdGood, thresholdPoor) => ({{
    type: 'line',
    data: {{
      labels,
      datasets: [
        {{ label, data, borderColor: color, backgroundColor: color + '20', fill: true, tension: 0.3, pointRadius: 3 }},
        {{ label: 'Good', data: Array(labels.length).fill(thresholdGood), borderColor: '#0cce6b40', borderDash: [5,5], pointRadius: 0 }},
        {{ label: 'Poor', data: Array(labels.length).fill(thresholdPoor), borderColor: '#ff4e4240', borderDash: [5,5], pointRadius: 0 }}
      ]
    }},
    options: {{ responsive: true, plugins: {{ legend: {{ labels: {{ color: '#94a3b8' }} }} }},
      scales: {{ x: {{ ticks: {{ color: '#94a3b8' }} }}, y: {{ ticks: {{ color: '#94a3b8' }} }} }} }}
  }});

  new Chart(document.getElementById('lcpChart'), chartOpts('LCP p75 (ms)', lcpValues, '#818cf8', 2500, 4000));
  new Chart(document.getElementById('clsChart'), chartOpts('CLS p75', clsValues, '#f472b6', 0.1, 0.25));
}}
</script>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Generate RUM Analytics HTML report")
    parser.add_argument("--data", required=True, help="Path to JSON data file")
    parser.add_argument("--output", required=True, help="Output HTML file path")
    args = parser.parse_args()

    with open(args.data, "r") as f:
        data = json.load(f)

    html = generate_html(data)

    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w") as f:
        f.write(html)

    print(f"Report generated: {args.output}")


if __name__ == "__main__":
    main()
