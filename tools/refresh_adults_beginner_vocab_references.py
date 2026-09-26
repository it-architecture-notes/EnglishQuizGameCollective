#!/usr/bin/env python3
"""
Refresh every adults-beginner vocabulary reference in one run:

  1. `update_final_word_counts_from_levels.py --flavor adults-beginner`
     -> refreshes `all-ai-common/references/final words/*.csv` and marks
        `all-ai-common/references/remove-word-list-references/3000 words oxford.txt`,
        scanning only `*/adults-beginner/questions.json` + `translations.json`.
  2. `gather_adults_beginner_level_words.py`
     -> `all-ai-common/output/adults-beginner-words-by-level.md`
  3. `gather_adults_beginner_level_words.py --word-index`
     -> `all-ai-common/output/adults-beginner-word-index.md`

Usage:
  python3 tools/refresh_adults_beginner_vocab_references.py
  python3 tools/refresh_adults_beginner_vocab_references.py --dry-run
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def run(cmd: list[str]) -> None:
    print(f"$ {' '.join(cmd)}")
    subprocess.run(cmd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "Preview the final-word-counts/Oxford-list step without writing it; the "
            "two gather-level-words outputs have no dry-run mode of their own, so "
            "they are skipped entirely in this mode"
        ),
    )
    args = parser.parse_args()

    root = repo_root()
    python = sys.executable
    tools = root / "tools"

    counts_cmd = [
        python,
        str(tools / "update_final_word_counts_from_levels.py"),
        "--flavor",
        "adults-beginner",
    ]
    if args.dry_run:
        counts_cmd.append("--dry-run")
    run(counts_cmd)

    if args.dry_run:
        print("[dry-run] Skipping gather_adults_beginner_level_words.py (no dry-run mode).")
        return 0

    run([python, str(tools / "gather_adults_beginner_level_words.py")])
    run([python, str(tools / "gather_adults_beginner_level_words.py"), "--word-index"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
