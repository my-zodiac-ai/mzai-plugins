#!/usr/bin/env python3
"""
lint-plugins.py — self-validation for the mzai-plugins marketplace.

Implements the CI checks from reports/audits/2026-06/03-UNIVERSAL-STANDARD.md §8:
  CI-1 broken references     CI-2 no hardcoded paths/IDs   CI-3 manifest hygiene
  CI-4 README counts         CI-5 skill frontmatter lint    CI-6 hook/script health
  CI-7 portability scan (core-* only)

Exit code: 1 if any ERROR, else 0. WARNINGS never fail the build.
Usage: python3 scripts/lint-plugins.py
"""
from __future__ import annotations
import json, re, subprocess, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PLUGINS = REPO / "plugins"
README = REPO / "README.md"
MARKET = REPO / ".claude-plugin" / "marketplace.json"
AUTHOR_CANON = "Valentyn Yakovliev"

errors: list[str] = []
warnings: list[str] = []
def err(c, m): errors.append(f"[{c}] {m}")
def warn(c, m): warnings.append(f"[{c}] {m}")

def rel(p: Path) -> str:
    try: return str(p.relative_to(REPO))
    except ValueError: return str(p)

# ── discover plugins (dirs with a manifest) ───────────────────────────────────
plugin_dirs = sorted(p for p in PLUGINS.iterdir()
                     if p.is_dir() and (p / ".claude-plugin" / "plugin.json").is_file())
plugin_names = [p.name for p in plugin_dirs]

def text_files(root: Path):
    for p in root.rglob("*"):
        if p.is_file() and not p.name.endswith(".bak") and p.suffix in {
            ".md", ".sh", ".py", ".json", ".js", ".ts", ".yml", ".yaml", ".txt"
        }:
            yield p

def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")

def frontmatter(md: str) -> dict | None:
    if not md.startswith("---"):
        return None
    m = re.match(r"^---\n(.*?)\n---", md, re.DOTALL)
    if not m:
        return None
    fm = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if mm:
            fm[mm.group(1)] = mm.group(2).strip()
    return fm

# ── CI-3: manifest hygiene ────────────────────────────────────────────────────
try:
    market = json.loads(read(MARKET))
    market_names = [p["name"] for p in market.get("plugins", [])]
    if sorted(market_names) != sorted(plugin_names):
        err("CI-3", f"marketplace.json plugins {sorted(market_names)} != plugins/ dirs {sorted(plugin_names)}")
    for entry in market.get("plugins", []):
        src = entry.get("source", "")
        if not (REPO / src.lstrip("./")).is_dir():
            err("CI-3", f"marketplace.json source not found: {entry.get('name')} -> {src}")
except Exception as e:
    err("CI-3", f"marketplace.json invalid: {e}")

for pd in plugin_dirs:
    mpath = pd / ".claude-plugin" / "plugin.json"
    try:
        man = json.loads(read(mpath))
    except Exception as e:
        err("CI-3", f"{rel(mpath)} invalid JSON: {e}")
        continue
    for field in ("name", "version", "description"):
        if not man.get(field):
            err("CI-3", f"{rel(mpath)} missing required field '{field}'")
    if man.get("name") != pd.name:
        err("CI-3", f"{rel(mpath)} name '{man.get('name')}' != dir '{pd.name}'")
    if man.get("name") and not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", man["name"]):
        err("CI-3", f"{rel(mpath)} name not kebab-case: '{man['name']}'")
    author = man.get("author")
    author_name = author.get("name") if isinstance(author, dict) else author
    if not author_name:
        warn("CI-3", f"{rel(mpath)} missing author")
    elif author_name not in (AUTHOR_CANON, "Anthropic"):
        warn("CI-3", f"{rel(mpath)} author '{author_name}' not normalized to '{AUTHOR_CANON}'")
    if not man.get("keywords"):
        warn("CI-3", f"{rel(mpath)} has no keywords")

# ── per-skill / per-agent checks (CI-1, CI-5) ─────────────────────────────────
SHELL_HINT = re.compile(r"```bash|`Bash\(|\bnpx \b|\bpnpm \b|subprocess|os\.system")
# Intra-plugin refs only: standalone `references/x` or `scripts/x` (not preceded
# by another path segment like `k6/scripts/...` or `other-plugin/references/...`).
REF_TOKEN = re.compile(r"(?<![\w/])(references/[A-Za-z0-9._/-]+\.[A-Za-z0-9]+|scripts/[A-Za-z0-9._/-]+\.[A-Za-z0-9]+)")

for pd in plugin_dirs:
    for skill in sorted(pd.glob("skills/*/SKILL.md")):
        md = read(skill)
        fm = frontmatter(md)
        sdir = skill.parent.name
        if fm is None:
            err("CI-5", f"{rel(skill)} missing/invalid YAML frontmatter")
        else:
            if not fm.get("name"):
                err("CI-5", f"{rel(skill)} frontmatter missing 'name'")
            elif fm["name"] != sdir:
                err("CI-5", f"{rel(skill)} name '{fm['name']}' != dir '{sdir}'")
            if not fm.get("description"):
                err("CI-5", f"{rel(skill)} frontmatter missing 'description'")
        nlines = md.count("\n") + 1
        if nlines > 500:
            warn("CI-5", f"{rel(skill)} body {nlines} lines > 500 (split into references/)")
        if SHELL_HINT.search(md) and (fm is None or "allowed-tools" not in fm):
            warn("CI-5", f"{rel(skill)} shells out but declares no 'allowed-tools'")
        # CI-1 broken refs inside the skill dir
        for tok in set(REF_TOKEN.findall(md)):
            if not (skill.parent / tok).exists():
                err("CI-1", f"{rel(skill)} references missing file: {tok}")
    for agent in sorted(pd.glob("agents/*.md")):
        fm = frontmatter(read(agent))
        if fm is None or not fm.get("name") or not fm.get("description"):
            err("CI-5", f"{rel(agent)} agent missing name/description frontmatter")

# ── CI-2: no hardcoded absolute paths / sandbox paths / MCP instance hashes ────
HARDCODE = [
    (re.compile(r"/Users/[A-Za-z0-9._-]+/"), "absolute /Users/ path"),
    (re.compile(r"/home/[A-Za-z0-9._-]+/"), "absolute /home/ path"),
    (re.compile(r"/sessions/[A-Za-z0-9-]+/"), "sandbox /sessions/ path"),
    (re.compile(r"mcp__[0-9a-f]{8}"), "MCP instance hash"),
    (re.compile(r"PROJECT_ROOT=[\"']?/(?!sessions)"), "hardcoded absolute PROJECT_ROOT"),
]
for pf in text_files(PLUGINS):
    content = read(pf)
    for rx, label in HARDCODE:
        if rx.search(content):
            for i, line in enumerate(content.splitlines(), 1):
                if rx.search(line):
                    err("CI-2", f"{rel(pf)}:{i} {label}: {line.strip()[:100]}")

# ── CI-4: README plugin presence + skill counts ───────────────────────────────
readme = read(README)
row_rx = re.compile(r"\|\s*\[`([a-z0-9-]+)`\]\([^)]*\)\s*\|\s*([0-9]+|—|-)\s*\|")
rows = {m.group(1): m.group(2) for m in row_rx.finditer(readme)}
for name in plugin_names:
    if name not in rows:
        err("CI-4", f"README has no table row for plugin '{name}'")
        continue
    declared = rows[name]
    if declared in ("—", "-"):
        continue
    actual = len(list((PLUGINS / name).glob("skills/*/SKILL.md")))
    if int(declared) != actual:
        err("CI-4", f"README count for '{name}' is {declared}, actual skills = {actual}")

# ── CI-7: portability scan (core-* plugins only) ──────────────────────────────
DOMAIN = re.compile(r"\b(astrolog|zodiac|cosmic|natal|horoscope|ephemeris|Quasar|Mongoose)\b", re.I)
for pd in plugin_dirs:
    if not pd.name.startswith("core-"):
        continue
    for skill in pd.glob("skills/*/SKILL.md"):
        md = read(skill)
        body = re.sub(r"##\s*Example.*", "", md, flags=re.DOTALL | re.I)  # allow examples
        if DOMAIN.search(body):
            warn("CI-7", f"{rel(skill)} core skill contains domain/stack term outside an Example block")

# ── CI-6: hook & script health ────────────────────────────────────────────────
for sh in PLUGINS.rglob("*.sh"):
    if sh.name.endswith(".bak"):
        continue
    r = subprocess.run(["bash", "-n", str(sh)], capture_output=True, text=True)
    if r.returncode != 0:
        err("CI-6", f"bash -n failed: {rel(sh)}: {r.stderr.strip()[:150]}")
for py in PLUGINS.rglob("*.py"):
    r = subprocess.run([sys.executable, "-m", "py_compile", str(py)], capture_output=True, text=True)
    if r.returncode != 0:
        err("CI-6", f"py_compile failed: {rel(py)}: {r.stderr.strip()[:150]}")
smoke = PLUGINS / "zodiac-hooks-pack" / "tests" / "smoke.sh"
if smoke.is_file():
    r = subprocess.run(["bash", str(smoke)], capture_output=True, text=True)
    if r.returncode != 0:
        err("CI-6", f"hooks smoke.sh failed:\n{r.stdout[-400:]}")

# ── report ────────────────────────────────────────────────────────────────────
print(f"mzai-plugins lint — {len(plugin_names)} plugins: {', '.join(plugin_names)}\n")
for w in warnings:
    print(f"  ⚠ {w}")
if warnings:
    print()
for e in errors:
    print(f"  ✗ {e}")
print()
if errors:
    print(f"FAIL — {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1)
print(f"PASS — 0 errors, {len(warnings)} warning(s)")
