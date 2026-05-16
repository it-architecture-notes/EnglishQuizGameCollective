#!/usr/bin/env python3
"""
Validate JSON syntax and minimal schema for files under ``app/assets/quiz-data/levels``.

Checks:
  Every ``*.json``: ``json.loads`` succeeds.
  ``translations.json``: root object, ``translations_list`` is a list; each item has
                        string ``english_word`` and optional ``translations`` object.
  ``questions.json``: root object, ``levelQuestions`` is a list.

Exit code 1 if any failure; prints path and reason.

Usage:
  python3 tools/validate_quiz_level_json.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def check_translations(rel: str, data: dict, issues: list[tuple[str, str]]) -> None:
    lst = data.get("translations_list")
    if lst is None:
        issues.append((rel, "missing translations_list"))
        return
    if not isinstance(lst, list):
        issues.append((rel, "translations_list must be a list"))
        return
    for i, e in enumerate(lst):
        if not isinstance(e, dict):
            issues.append((rel, f"translations_list[{i}] must be an object"))
            continue
        ew = e.get("english_word")
        if ew is None:
            issues.append((rel, f"translations_list[{i}] missing english_word"))
        elif not isinstance(ew, str):
            issues.append((rel, f"translations_list[{i}] english_word must be a string"))
        if "translations" in e and not isinstance(e["translations"], dict):
            issues.append((rel, f"translations_list[{i}] translations must be an object"))


def check_questions(rel: str, data: dict, issues: list[tuple[str, str]]) -> None:
    rows = data.get("levelQuestions")
    if rows is None:
        issues.append((rel, "missing levelQuestions"))
    elif not isinstance(rows, list):
        issues.append((rel, "levelQuestions must be a list"))


def main() -> int:
    root = repo_root()
    levels = (root / "app" / "assets" / "quiz-data" / "levels").resolve()
    if not levels.is_dir():
        print(f"Not a directory: {levels}", file=sys.stderr)
        return 1

    issues: list[tuple[str, str]] = []

    for path in sorted(levels.rglob("*.json")):
        rel = path.relative_to(levels).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
            if text.startswith("\ufeff"):
                text = text.lstrip("\ufeff")
            data = json.loads(text)
        except json.JSONDecodeError as e:
            issues.append((rel, f"invalid JSON: {e}"))
            continue

        if not isinstance(data, dict):
            issues.append((rel, "root must be a JSON object"))
            continue

        if path.name == "translations.json":
            check_translations(rel, data, issues)
        elif path.name == "questions.json":
            check_questions(rel, data, issues)

    for rel, msg in issues:
        print(f"{rel}: {msg}")
    if issues:
        print(f"{len(issues)} issue(s)", file=sys.stderr)
        return 1
    print(f"OK: {levels} — all JSON files valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
