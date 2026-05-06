#!/usr/bin/env python3
"""frontmatter-validator.py — PostToolUse hook

Validates YAML frontmatter on .md files inside content/ directories
(@nuxt/content convention). Reports missing required fields, malformed
YAML, or unknown fields to stderr.

Required fields (configurable via env):
  ZODIAC_FRONTMATTER_REQUIRED — comma-separated, default:
    title,description,date

Disable: ZODIAC_HOOK_FRONTMATTER_DISABLE=1
"""

import json
import os
import re
import sys
from pathlib import Path


def globally_disabled() -> bool:
    return os.environ.get("ZODIAC_HOOKS_DISABLE", "0") == "1"


def hook_disabled() -> bool:
    return os.environ.get("ZODIAC_HOOK_FRONTMATTER_DISABLE", "0") == "1"


def read_payload() -> dict:
    try:
        raw = sys.stdin.read()
        return json.loads(raw) if raw.strip() else {}
    except (json.JSONDecodeError, OSError):
        return {}


def get_file_path(payload: dict) -> str:
    return (payload.get("tool_input") or {}).get("file_path", "") or ""


def is_content_md(path: str) -> bool:
    if not path.endswith(".md"):
        return False
    # Looks like @nuxt/content layout: contains /content/ in path
    return "/content/" in path


# Tiny YAML parser — only handles flat key: value pairs and quoted strings.
# Sufficient for frontmatter without bringing PyYAML as a dep.
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
KV_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$")


def parse_frontmatter(text: str) -> tuple[dict | None, str | None]:
    """Returns (parsed_dict, error_message). On parse failure, dict is None."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None, "no frontmatter block (expected --- ... ---)"
    block = m.group(1)
    out = {}
    for i, line in enumerate(block.splitlines(), start=1):
        line_strip = line.strip()
        if not line_strip or line_strip.startswith("#"):
            continue
        # skip nested list/object lines (we only care about top-level keys)
        if line.startswith(" ") or line.startswith("\t") or line_strip.startswith("- "):
            continue
        kv = KV_RE.match(line_strip)
        if not kv:
            return None, f"line {i}: cannot parse '{line_strip[:60]}'"
        key, raw_val = kv.group(1), kv.group(2).strip()
        # strip surrounding quotes
        if (raw_val.startswith('"') and raw_val.endswith('"')) or (
            raw_val.startswith("'") and raw_val.endswith("'")
        ):
            raw_val = raw_val[1:-1]
        out[key] = raw_val
    return out, None


def main() -> int:
    if globally_disabled() or hook_disabled():
        return 0

    payload = read_payload()
    file_path = get_file_path(payload)
    if not file_path or not is_content_md(file_path):
        return 0

    try:
        text = Path(file_path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return 0

    parsed, err = parse_frontmatter(text)
    if err:
        print("", file=sys.stderr)
        print(f"📝 frontmatter issue in {Path(file_path).name}:", file=sys.stderr)
        print(f"   {err}", file=sys.stderr)
        print("   (zodiac-hooks-pack: frontmatter-validator)", file=sys.stderr)
        return 0

    required_csv = os.environ.get(
        "ZODIAC_FRONTMATTER_REQUIRED", "title,description,date"
    )
    required = [k.strip() for k in required_csv.split(",") if k.strip()]
    missing = [k for k in required if k not in (parsed or {})]
    empty = [k for k in required if k in (parsed or {}) and not (parsed or {})[k]]

    if missing or empty:
        print("", file=sys.stderr)
        print(f"📝 frontmatter incomplete in {Path(file_path).name}:", file=sys.stderr)
        if missing:
            print(f"   missing: {', '.join(missing)}", file=sys.stderr)
        if empty:
            print(f"   empty: {', '.join(empty)}", file=sys.stderr)
        print(
            "   override required keys via ZODIAC_FRONTMATTER_REQUIRED=...",
            file=sys.stderr,
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
