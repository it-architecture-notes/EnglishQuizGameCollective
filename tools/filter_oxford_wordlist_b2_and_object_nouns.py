#!/usr/bin/env python3
"""
Filter an Oxford-style word list (one entry per line: ``headword pos. levels…``).

Removes lines that:
  1. Contain CEFR level ``B2`` anywhere on the line (e.g. ``v. B2`` or ``n. A1, v. B2``).
  2. Are noun entries (`` n.`` / ``\\bn\\.``) whose headword matches the concrete-noun
     lemmas derived from ``remove-word-list-references/300 noun words.json`` (hyphen
     compounds expand to each segment; simple English plural stems are added).

Usage:
  python3 tools/filter_oxford_wordlist_b2_and_object_nouns.py --dry-run
  python3 tools/filter_oxford_wordlist_b2_and_object_nouns.py -o out.txt
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


B2_RE = re.compile(r"\bB2\b")
NOUN_RE = re.compile(r"\bn\.")


def expand_object_lemmas(entries: list[str]) -> set[str]:
    """Lowercase lemmas for matching Oxford headwords (first column, * stripped)."""
    out: set[str] = set()
    for raw in entries:
        e = str(raw).lower().strip()
        if not e:
            continue
        parts = e.split("-")
        for part in parts:
            p = part.strip()
            if not p:
                continue
            out.add(p)
            # crude singular / variant hints for Oxford singular headwords
            if p.endswith("ies") and len(p) > 4:
                out.add(p[:-3] + "y")  # cherries -> cherry
            if p.endswith("es") and len(p) > 3:
                out.add(p[:-2])  # buses -> bus (imperfect)
                if p.endswith("ches") or p.endswith("shes"):
                    out.add(p[:-2])
            if p.endswith("s") and not p.endswith("ss") and len(p) > 2:
                out.add(p[:-1])  # apples -> apple
    return out


def headword(line: str) -> str:
    s = line.strip()
    if not s:
        return ""
    first = s.split()[0]
    return first.strip("*").lower()


def should_drop(line: str, object_lemmas: set[str]) -> bool:
    if B2_RE.search(line):
        return True
    if not NOUN_RE.search(line):
        return False
    hw = headword(line)
    if not hw:
        return False
    return hw in object_lemmas


def main() -> int:
    root = repo_root()
    default_oxford = (
        root
        / "cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt"
    )
    default_nouns = (
        root
        / "cursor-claude-common/references/remove-word-list-references/300 noun words.json"
    )

    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--oxford", type=Path, default=default_oxford, help="Input word list")
    p.add_argument(
        "--object-nouns-json",
        type=Path,
        default=default_nouns,
        help="JSON with {\"nouns\": [...]} concrete noun slugs",
    )
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output path (default: overwrite --oxford)",
    )
    p.add_argument("--dry-run", action="store_true", help="Print counts only; do not write")
    args = p.parse_args()

    oxford = args.oxford.resolve()
    nouns_path = args.object_nouns_json.resolve()
    out_path = (args.output or args.oxford).resolve()

    if not oxford.is_file():
        print(f"error: not a file: {oxford}", file=sys.stderr)
        return 1
    if not nouns_path.is_file():
        print(f"error: not a file: {nouns_path}", file=sys.stderr)
        return 1

    try:
        data = json.loads(nouns_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"error: cannot read JSON: {e}", file=sys.stderr)
        return 1
    entries = data.get("nouns")
    if not isinstance(entries, list):
        print("error: JSON must contain a 'nouns' array", file=sys.stderr)
        return 1

    object_lemmas = expand_object_lemmas([str(x) for x in entries])

    text = oxford.read_text(encoding="utf-8")
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")
    lines = text.splitlines()

    kept: list[str] = []
    drop_b2 = 0
    drop_obj = 0
    for line in lines:
        b2 = bool(B2_RE.search(line))
        obj = False
        if not b2:
            obj = bool(
                NOUN_RE.search(line)
                and headword(line)
                and headword(line) in object_lemmas
            )
        if b2:
            drop_b2 += 1
            continue
        if obj:
            drop_obj += 1
            continue
        kept.append(line)

    if args.dry_run:
        print(
            f"[dry-run] {oxford}: total lines={len(lines)}, "
            f"would drop B2={drop_b2}, object-noun={drop_obj}, "
            f"would keep={len(kept)}"
        )
        return 0

    body = "\n".join(kept)
    if body:
        body += "\n"
    out_path.write_text(body, encoding="utf-8")
    print(
        f"Wrote {out_path}: removed B2={drop_b2}, object-noun={drop_obj}, "
        f"kept={len(kept)} (from {len(lines)} lines)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
