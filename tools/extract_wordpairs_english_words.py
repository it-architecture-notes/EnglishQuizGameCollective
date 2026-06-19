#!/usr/bin/env python3
"""
Collect every `english_words` entry from `WordPairs` questions in level JSON.

Scans all `questions.json` files under `app/assets/quiz-data/levels/` (recursive).
For each question with `template` `WordPairs` or legacy `ConvoTemplate-WordPairs`,
reads `questionData.english_words` (array of strings). Empty strings are skipped.

Output CSV (default: `cursor-claude-common/output/wordpairs-english-words-by-level.csv`):
  english_word,level

Rows are sorted by level path, then english_word (case-insensitive). Level is the
folder path relative to the levels root (e.g. `at-the-farm`, `implemented/kitchen`).

Usage:
  python3 tools/extract_wordpairs_english_words.py
  python3 tools/extract_wordpairs_english_words.py --output /tmp/wordpairs.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

_WORD_PAIRS_TEMPLATE_IDS = frozenset({"WordPairs", "ConvoTemplate-WordPairs"})


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


def collect_rows(levels_root: Path) -> tuple[list[tuple[str, str]], list[str]]:
    """Return (sorted csv rows, warning messages for skipped files)."""
    rows: list[tuple[str, str]] = []
    warnings: list[str] = []
    for qpath in sorted(levels_root.rglob("questions.json")):
        if not qpath.is_file():
            continue
        level_name = qpath.parent.relative_to(levels_root).as_posix()
        try:
            words = english_words_from_questions(qpath)
        except (OSError, json.JSONDecodeError) as e:
            warnings.append(f"Skip {qpath}: {e}")
            continue
        for word in words:
            rows.append((word, level_name))
    rows.sort(key=lambda r: (r[1].lower(), r[0].lower()))
    return rows, warnings


def write_csv(path: Path, rows: list[tuple[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["english_word", "level"])
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
    args = parser.parse_args()

    levels_root = args.levels_root.resolve()
    if not levels_root.is_dir():
        print(f"Not a directory: {levels_root}", file=sys.stderr)
        return 1

    output_path = args.output
    if not output_path.is_absolute():
        output_path = (root / output_path).resolve()

    rows, warnings = collect_rows(levels_root)
    for msg in warnings:
        print(msg, file=sys.stderr)

    write_csv(output_path, rows)
    level_count = len({level for _, level in rows})
    print(
        f"Wrote {output_path} ({len(rows)} rows from {level_count} level(s) with WordPairs)."
    )
    if warnings:
        print(f"  {len(warnings)} file(s) skipped due to read/parse errors.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
