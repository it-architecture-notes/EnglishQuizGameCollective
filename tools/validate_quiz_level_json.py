#!/usr/bin/env python3
"""
Validate JSON syntax and minimal schema for files under ``app/assets/quiz-data/levels``.

Checks:
  Every ``*.json``: ``json.loads`` succeeds.
  ``translations.json``: root object, ``translations_list`` is a list; each item has
                        string ``english_word`` and optional ``translations`` object.
  ``questions.json``: root object, ``levelQuestions`` is a list. Rows whose
                        ``template`` is one of GENDERED_TEMPLATES must carry a
                        top-level ``genders`` casting code (paired ``m-f`` style
                        for PAIRED_GENDER_TEMPLATES, single ``m``/``f`` for the
                        rest). If the row also has an authored
                        ``questionData.character1``/``character2``, that name's
                        gender (looked up in ``conversation_characters.json``'s
                        ``en`` pool) must match the corresponding half of
                        ``genders`` — this is what keeps the picked/authored
                        character consistent with the casting code voice/art
                        tooling reads.

Exit code 1 if any failure; prints path and reason.

Usage:
  python3 tools/validate_quiz_level_json.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Templates that must carry a mandatory top-level "genders" casting code.
PAIRED_GENDER_TEMPLATES = {"ConvoTemplate-1", "DialogueCompletion"}
SINGLE_GENDER_TEMPLATES = {"AppearDisappear", "ClozeSequence", "SentenceBuilder", "GrammarForm"}
GENDERED_TEMPLATES = PAIRED_GENDER_TEMPLATES | SINGLE_GENDER_TEMPLATES

VALID_PAIRED_CODES = {"m-m", "f-m", "m-f", "f-f"}
VALID_SINGLE_CODES = {"m", "f"}


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def load_name_gender_lookup(root: Path) -> dict[str, str]:
    """Maps every name in conversation_characters.json's `en` pool to 'm'/'f'."""
    path = root / "app" / "assets" / "data" / "config" / "conversation_characters.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    en = (data.get("characterNamePools") or {}).get("en") or {}
    lookup: dict[str, str] = {}
    for name in en.get("male") or []:
        lookup[str(name).strip().lower()] = "m"
    for name in en.get("female") or []:
        lookup[str(name).strip().lower()] = "f"
    return lookup


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


def check_genders_field(
    rel: str, i: int, row: dict, name_gender: dict[str, str], issues: list[tuple[str, str]]
) -> None:
    template = row.get("template")
    if template not in GENDERED_TEMPLATES:
        return

    genders = row.get("genders")
    if not isinstance(genders, str) or not genders.strip():
        issues.append((rel, f"levelQuestions[{i}] ({template}) missing required 'genders'"))
        return
    genders = genders.strip().lower()

    if template in PAIRED_GENDER_TEMPLATES:
        if genders not in VALID_PAIRED_CODES:
            issues.append(
                (rel, f"levelQuestions[{i}] ({template}) genders={genders!r} "
                      f"must be one of {sorted(VALID_PAIRED_CODES)}")
            )
            return
        code1, code2 = genders.split("-")
        qd = row.get("questionData") or {}
        for field, code in (("character1", code1), ("character2", code2)):
            name = qd.get(field)
            if not isinstance(name, str) or not name.strip():
                continue
            actual = name_gender.get(name.strip().lower())
            if actual is not None and actual != code:
                issues.append((
                    rel,
                    f"levelQuestions[{i}] ({template}) questionData.{field}={name!r} "
                    f"is {actual!r} but genders={genders!r} says {code!r}",
                ))
    else:
        if genders not in VALID_SINGLE_CODES:
            issues.append(
                (rel, f"levelQuestions[{i}] ({template}) genders={genders!r} "
                      f"must be one of {sorted(VALID_SINGLE_CODES)}")
            )


def check_questions(
    rel: str, data: dict, name_gender: dict[str, str], issues: list[tuple[str, str]]
) -> None:
    rows = data.get("levelQuestions")
    if rows is None:
        issues.append((rel, "missing levelQuestions"))
        return
    if not isinstance(rows, list):
        issues.append((rel, "levelQuestions must be a list"))
        return
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            issues.append((rel, f"levelQuestions[{i}] must be an object"))
            continue
        check_genders_field(rel, i, row, name_gender, issues)


def main() -> int:
    root = repo_root()
    levels = (root / "app" / "assets" / "quiz-data" / "levels").resolve()
    if not levels.is_dir():
        print(f"Not a directory: {levels}", file=sys.stderr)
        return 1

    issues: list[tuple[str, str]] = []
    name_gender = load_name_gender_lookup(root)

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
            check_questions(rel, data, name_gender, issues)

    for rel, msg in issues:
        print(f"{rel}: {msg}")
    if issues:
        print(f"{len(issues)} issue(s)", file=sys.stderr)
        return 1
    print(f"OK: {levels} — all JSON files valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
