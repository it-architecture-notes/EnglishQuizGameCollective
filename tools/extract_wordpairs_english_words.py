#!/usr/bin/env python3
"""
Collect every `english_words` entry from `WordPairs` questions in level JSON.

Scans all `questions.json` files under `app/assets/quiz-data/levels/` (recursive
— this picks up both `{level}/adults/questions.json` and `{level}/kids/questions.json`,
since every level is flavor-split now; no root questions.json exists anymore).
For each question with `template` `WordPairs` or legacy `ConvoTemplate-WordPairs`,
reads `questionData.english_words` (array of strings). Empty strings are skipped.

Output CSV (default: `cursor-claude-common/output/wordpairs-english-words-by-level.csv`):
  english_word,level,flavor

Rows are sorted by level, then flavor, then english_word (case-insensitive).
`level` is the flavor-split folder's parent (e.g. `at-the-farm`, not
`at-the-farm/adults`) — use `flavor` to distinguish adults vs kids rows, or
pass --flavor to only scan one.

Usage:
  python3 tools/extract_wordpairs_english_words.py
  python3 tools/extract_wordpairs_english_words.py --flavor kids
  python3 tools/extract_wordpairs_english_words.py --output /tmp/wordpairs.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

_WORD_PAIRS_TEMPLATE_IDS = frozenset({"WordPairs", "ConvoTemplate-WordPairs"})
_FLAVORS = ("adults", "kids")


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def english_words_from_questions(path: Path) -> list[str]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        raise
    rows = data.get("levelQuestions")
    if not isinstance(rows, list):
        return []
    out: list[str] = []
    for item in rows:
        if not isinstance(item, dict):
            continue
        tpl = item.get("template")
        if tpl not in _WORD_PAIRS_TEMPLATE_IDS:
            continue
        qd = item.get("questionData")
        if not isinstance(qd, dict):
            continue
        words = qd.get("english_words")
        if not isinstance(words, list):
            continue
        for w in words:
            s = str(w).strip() if w is not None else ""
            if s:
                out.append(s)
    return out


def collect_rows(
    levels_root: Path, flavor_filter: str | None
) -> tuple[list[tuple[str, str, str]], list[str]]:
    """Return (sorted (word, level, flavor) rows, warning messages for skipped files)."""
    rows: list[tuple[str, str, str]] = []
    warnings: list[str] = []
    for qpath in sorted(levels_root.rglob("questions.json")):
        if not qpath.is_file():
            continue
        parent_name = qpath.parent.name
        if parent_name in _FLAVORS:
            flavor = parent_name
            level_name = qpath.parent.parent.relative_to(levels_root).as_posix()
        else:
            # Legacy root questions.json (shouldn't exist anymore, kept as a
            # safety net so this script doesn't just silently drop the file).
            flavor = "legacy"
            level_name = qpath.parent.relative_to(levels_root).as_posix()
        if flavor_filter and flavor != flavor_filter:
            continue
        try:
            words = english_words_from_questions(qpath)
        except (OSError, json.JSONDecodeError) as e:
            warnings.append(f"Skip {qpath}: {e}")
            continue
        for word in words:
            rows.append((word, level_name, flavor))
    rows.sort(key=lambda r: (r[1].lower(), r[2], r[0].lower()))
    return rows, warnings


def write_csv(path: Path, rows: list[tuple[str, str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["english_word", "level", "flavor"])
        w.writerows(rows)


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
        help="Root folder containing level subfolders",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "cursor-claude-common/output/wordpairs-english-words-by-level.csv",
        help="Output CSV path",
    )
    parser.add_argument(
        "--flavor",
        choices=_FLAVORS,
        default=None,
        help="Only scan this flavor's questions.json (default: both, with a "
        "flavor column in the output)",
    )
    args = parser.parse_args()

    levels_root = args.levels_root.resolve()
    if not levels_root.is_dir():
        print(f"Not a directory: {levels_root}", file=sys.stderr)
        return 1

    output_path = args.output
    if not output_path.is_absolute():
        output_path = (root / output_path).resolve()

    rows, warnings = collect_rows(levels_root, args.flavor)
    for msg in warnings:
        print(msg, file=sys.stderr)

    write_csv(output_path, rows)
    level_count = len({level for _, level, _ in rows})
    print(
        f"Wrote {output_path} ({len(rows)} rows from {level_count} level(s) with WordPairs)."
    )
    if warnings:
        print(f"  {len(warnings)} file(s) skipped due to read/parse errors.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
