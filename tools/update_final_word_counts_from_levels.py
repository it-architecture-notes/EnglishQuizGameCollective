#!/usr/bin/env python3
"""
Scan quiz level JSON and refresh `count` + `levels` columns in the CSV files under
`cursor-claude-common/references/final words/`.

Counted sources (per level folder — each word/phrase contributes at most once per level):
  questions.json
    - Skip questions whose `template` starts with `imageQuizTemplate`.
    - For other templates, only `questionData` keys: `words`, `answers`, `answer`,
      `english_words` (strings, arrays of strings, or scalar coerced to string).

  translations.json
    - Only `english_word` in each `translations_list` entry.

Matching: CSV `word` matches if its lowercase form equals any token extracted from
the counted text, or equals the whole normalized phrase (for multi-word `word` rows).

Output CSV header: word,level,count,levels
  - count: number of distinct level folders where the word matched.
  - levels: comma-separated relative paths from the levels root (sorted).

Usage:
  python3 tools/update_final_word_counts_from_levels.py
  python3 tools/update_final_word_counts_from_levels.py --dry-run
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path

TOKEN_RE = re.compile(r"[a-z0-9]+(?:[-'][a-z0-9]+)*", re.IGNORECASE)

# Fields to read inside questionData (non-image templates only).
_QD_COUNTED_KEYS = frozenset({"words", "answers", "answer", "english_words"})


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def tokenize(text: str) -> list[str]:
    return [m.group(0).lower() for m in TOKEN_RE.finditer(text or "")]


def normalize_phrase(text: str) -> str:
    return " ".join((text or "").strip().split()).lower()


def add_value_to_bucket(raw, bucket: set[str]) -> None:
    """Add full phrase + tokens from a string or list of strings."""
    if raw is None:
        return
    if isinstance(raw, list):
        for item in raw:
            add_value_to_bucket(item, bucket)
        return
    s = str(raw).strip()
    if not s:
        return
    phrase = normalize_phrase(s)
    if phrase:
        bucket.add(phrase)
    for t in tokenize(s):
        bucket.add(t)


def vocabulary_from_questions(path: Path) -> set[str]:
    bucket: set[str] = set()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return bucket
    rows = data.get("levelQuestions")
    if not isinstance(rows, list):
        return bucket
    for item in rows:
        if not isinstance(item, dict):
            continue
        tpl = item.get("template")
        if isinstance(tpl, str) and tpl.startswith("imageQuizTemplate"):
            continue
        qd = item.get("questionData")
        if not isinstance(qd, dict):
            continue
        for key in _QD_COUNTED_KEYS:
            if key in qd:
                add_value_to_bucket(qd[key], bucket)
    return bucket


def vocabulary_from_translations(path: Path) -> set[str]:
    bucket: set[str] = set()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return bucket
    lst = data.get("translations_list")
    if not isinstance(lst, list):
        return bucket
    for entry in lst:
        if not isinstance(entry, dict):
            continue
        add_value_to_bucket(entry.get("english_word"), bucket)
    return bucket


def iter_level_dirs(levels_root: Path) -> set[Path]:
    found: set[Path] = set()
    for pattern in ("questions.json", "translations.json"):
        for p in levels_root.rglob(pattern):
            if p.is_file():
                found.add(p.parent.resolve())
    return found


def level_label(level_dir: Path, levels_root: Path) -> str:
    try:
        return level_dir.resolve().relative_to(levels_root.resolve()).as_posix()
    except ValueError:
        return level_dir.name


def collect_word_to_levels(levels_root: Path) -> dict[str, set[str]]:
    """Lowercase word/phrase key -> set of level relative paths."""
    word_levels: dict[str, set[str]] = {}
    for d in sorted(iter_level_dirs(levels_root)):
        bucket: set[str] = set()
        qp = d / "questions.json"
        tp = d / "translations.json"
        if qp.is_file():
            bucket |= vocabulary_from_questions(qp)
        if tp.is_file():
            bucket |= vocabulary_from_translations(tp)
        if not bucket:
            continue
        label = level_label(d, levels_root)
        for w in bucket:
            word_levels.setdefault(w, set()).add(label)
    return word_levels


def match_csv_word(csv_word: str, word_levels: dict[str, set[str]]) -> tuple[int, str]:
    """
    Return (count, comma-separated sorted level names).
    csv_word may be multi-word; try whole phrase then tokens.
    """
    key = (csv_word or "").strip()
    if not key:
        return 0, ""
    seen_levels: set[str] = set()
    phrase = normalize_phrase(key)
    if phrase in word_levels:
        seen_levels |= word_levels[phrase]
    for tok in tokenize(key):
        if tok in word_levels:
            seen_levels |= word_levels[tok]
    levels_str = ",".join(sorted(seen_levels))
    return len(seen_levels), levels_str


def _normalize_headers(fieldnames: list[str] | None) -> dict[str, str]:
    """Map canonical keys word, level, count to actual CSV header names."""
    if not fieldnames:
        return {}
    lower_map = {f.lower(): f for f in fieldnames}
    out: dict[str, str] = {}
    for canon, aliases in (
        ("word", ("word", "adverb")),
        ("level", ("level",)),
        ("count", ("count",)),
    ):
        for a in aliases:
            if a in lower_map:
                out[canon] = lower_map[a]
                break
    return out


def update_csv(path: Path, word_levels: dict[str, set[str]], dry_run: bool) -> int:
    """Returns number of rows updated. Rewrites CSV with word,level,count,levels."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"Skip {path}: {e}", file=sys.stderr)
        return 0
    # Strip BOM
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")
    reader = csv.DictReader(text.splitlines())
    hdr_map = _normalize_headers(reader.fieldnames)
    if "word" not in hdr_map:
        print(f"Skip {path}: missing word column (expected word or Adverb)", file=sys.stderr)
        return 0
    wkey, lkey, ckey = hdr_map["word"], hdr_map.get("level", "level"), hdr_map.get("count", "count")
    fieldnames = ["word", "level", "count", "levels"]
    rows_out: list[dict[str, str]] = []
    n = 0
    for row in reader:
        if not row:
            continue
        word = (row.get(wkey) or "").strip()
        lev = (row.get(lkey) or "").strip()
        cnt, levels_str = match_csv_word(word, word_levels)
        rows_out.append(
            {
                "word": word,
                "level": lev,
                "count": str(cnt),
                "levels": levels_str,
            }
        )
        n += 1
    if dry_run:
        print(f"[dry-run] Would rewrite {path} ({n} rows)")
        return n
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows_out)
    print(f"Wrote {path} ({n} rows)")
    return n


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
        "--csv-dir",
        type=Path,
        default=root / "cursor-claude-common/references/final words",
        help="Folder with word*.csv files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions without writing CSV files",
    )
    args = parser.parse_args()

    levels_root = args.levels_root.resolve()
    if not levels_root.is_dir():
        print(f"Not a directory: {levels_root}", file=sys.stderr)
        return 1

    csv_dir = args.csv_dir.resolve()
    if not csv_dir.is_dir():
        print(f"Not a directory: {csv_dir}", file=sys.stderr)
        return 1

    word_levels = collect_word_to_levels(levels_root)
    print(f"Indexed vocabulary from {levels_root} ({len(word_levels)} distinct tokens/phrases).")

    total_rows = 0
    for csv_path in sorted(csv_dir.glob("*.csv")):
        total_rows += update_csv(csv_path, word_levels, args.dry_run)

    print(f"Done. Processed rows across files: {total_rows}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
