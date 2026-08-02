#!/usr/bin/env python3
"""
Consolidate every kids non-image question, across every level, into one file —
for reviewing vocabulary/grammar across the whole kids flow at a glance.

Reads ``app/assets/data/flow/game-flow-kids.json`` for level order + mainLevel
grouping, then each level's ``kids/questions.json`` (falling back to a root
``questions.json`` for any level not yet split into flavor folders).

Skips image-only templates (imageQuizTemplate-1/-2/-3/-SentenceChoice) — no
meaningful "question text" to review there, just an image + a label.

Usage:
  python3 tools/gather_all_kids_questions.py
  python3 tools/gather_all_kids_questions.py --format json
  python3 tools/gather_all_kids_questions.py -o somewhere/else.md

Output (default):
  cursor-claude-common/output/kids-all-mixed-questions.md
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_IMAGE_TEMPLATES = {
    "imageQuizTemplate-1",
    "imageQuizTemplate-2",
    "imageQuizTemplate-3",
    "imageQuizTemplate-SentenceChoice",
}


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def load_flow_levels(flow_path: Path) -> list[tuple[int, str]]:
    """Returns ordered [(mainLevel, directoryName), ...], reminders skipped,
    de-duplicated by (mainLevel, directoryName) so a repeated level (e.g.
    at-the-airport appearing twice) isn't read/emitted twice per ML."""
    data = json.loads(flow_path.read_text(encoding="utf-8"))
    seen: set[tuple[int, str]] = set()
    out: list[tuple[int, str]] = []
    for entry in data:
        if not isinstance(entry, dict) or entry.get("kind") == "reminder":
            continue
        name = entry.get("directoryName")
        ml = entry.get("mainLevel")
        if not isinstance(name, str) or not name.strip() or not isinstance(ml, int):
            continue
        key = (ml, name)
        if key in seen:
            continue
        seen.add(key)
        out.append((ml, name))
    return out


def load_questions(levels_root: Path, directory_name: str) -> list[dict] | None:
    kids_path = levels_root / directory_name / "kids" / "questions.json"
    root_path = levels_root / directory_name / "questions.json"
    path = kids_path if kids_path.is_file() else root_path
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    rows = data.get("levelQuestions")
    return rows if isinstance(rows, list) else None


def stringify(value) -> str:
    if value is None:
        return ""
    if isinstance(value, list):
        return " / ".join(stringify(v) for v in value)
    return str(value)


def extract_row(row: dict) -> dict | None:
    """Returns a compact dict describing one non-image question, or None to skip."""
    template = row.get("template", "")
    if template in _IMAGE_TEMPLATES:
        return None
    qd = row.get("questionData")
    if not isinstance(qd, dict):
        return None

    out: dict[str, str] = {"template": template, "genders": row.get("genders", "")}

    if template in ("ConvoTemplate-1",):
        out["line1"] = stringify(qd.get("line1"))
        out["line2"] = stringify(qd.get("line2"))
        out["answer"] = stringify(qd.get("answer"))
        out["distractors"] = stringify(qd.get("distractors"))
    elif template == "DialogueCompletion":
        out["line1"] = stringify(qd.get("line1"))
        out["answer"] = stringify(qd.get("answer"))
        out["distractors"] = stringify(qd.get("distractors"))
    elif template == "ClozeSequence":
        out["sentence"] = stringify(qd.get("sentence"))
        out["answer"] = stringify(qd.get("answers", qd.get("answer")))
        out["distractors"] = stringify(qd.get("distractors"))
    elif template == "SentenceBuilder":
        out["correct_order"] = stringify(qd.get("correct_order"))
    elif template == "AppearDisappear":
        out["words"] = stringify(qd.get("words"))
        out["distractors"] = stringify(qd.get("distractors"))
    elif template == "GrammarForm":
        out["sentence"] = stringify(qd.get("sentence"))
        out["answer"] = stringify(qd.get("answer"))
        out["distractors"] = stringify(qd.get("distractors"))
    elif template == "WordPairs":
        out["english_words"] = stringify(qd.get("english_words"))
    else:
        # Unknown/future template: keep it visible rather than silently dropping.
        out["raw"] = stringify(qd)

    return out


def gather(levels_root: Path, flow_path: Path) -> list[dict]:
    """Returns [{mainLevel, level, questions: [extracted, ...]}, ...] in flow order."""
    out: list[dict] = []
    for main_level, level_name in load_flow_levels(flow_path):
        rows = load_questions(levels_root, level_name)
        if rows is None:
            continue
        extracted = [r for r in (extract_row(row) for row in rows) if r is not None]
        if not extracted:
            continue
        out.append(
            {"mainLevel": main_level, "level": level_name, "questions": extracted}
        )
    return out


def render_markdown(sections: list[dict]) -> str:
    lines = ["# Kids questions — all levels, all main levels (image templates skipped)", ""]
    current_ml: int | None = None
    for section in sections:
        ml = section["mainLevel"]
        if ml != current_ml:
            lines.append(f"## Main Level {ml}")
            lines.append("")
            current_ml = ml
        lines.append(f"### {section['level']}")
        lines.append("")
        for i, q in enumerate(section["questions"]):
            parts = [f"**{i}. {q['template']}**"]
            if q.get("genders"):
                parts.append(f"_(genders: {q['genders']})_")
            lines.append(" ".join(parts))
            for key, val in q.items():
                if key in ("template", "genders") or not val:
                    continue
                lines.append(f"- {key}: {val}")
            lines.append("")
    return "\n".join(lines) + "\n"


def render_json(sections: list[dict]) -> str:
    return json.dumps(sections, indent=2, ensure_ascii=False) + "\n"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    root = repo_root()
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
    )
    p.add_argument(
        "--flow",
        type=Path,
        default=root / "app/assets/data/flow/game-flow-kids.json",
    )
    p.add_argument("--format", choices=("md", "json"), default="md")
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Default: cursor-claude-common/output/kids-all-mixed-questions.<ext>",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    root = repo_root()

    sections = gather(args.levels_root.resolve(), args.flow.resolve())

    ext = "md" if args.format == "md" else "json"
    output_path = args.output or (
        root / "cursor-claude-common/output" / f"kids-all-mixed-questions.{ext}"
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)

    body = render_markdown(sections) if args.format == "md" else render_json(sections)
    output_path.write_text(body, encoding="utf-8")

    total_questions = sum(len(s["questions"]) for s in sections)
    print(
        f"Wrote {output_path} — {len(sections)} levels, {total_questions} "
        f"non-image questions",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
