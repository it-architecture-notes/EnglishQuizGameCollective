#!/usr/bin/env python3
"""Audit level image folders vs imageQuizTemplate-1/2 references in questions.json."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEVELS_DIR = ROOT / "app" / "assets" / "quiz-data" / "levels"
OUTPUT = ROOT / "cursor-claude-common" / "output" / "image-folder-audit.md"

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}


def folder_images(level_dir: Path) -> set[str]:
    names: set[str] = set()
    for p in level_dir.iterdir():
        if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES:
            names.add(p.stem)
    return names


def collect_question_images(questions_path: Path) -> tuple[set[str], list[str]]:
    """Return (image stems needed on disk, human-readable notes)."""
    needed: set[str] = set()
    notes: list[str] = []

    with questions_path.open(encoding="utf-8") as f:
        data = json.load(f)

    for i, q in enumerate(data.get("levelQuestions", []), start=1):
        template = q.get("template", "")
        qd = q.get("questionData") or {}

        if template == "imageQuizTemplate-1":
            image_name = (qd.get("imageName") or "").strip()
            if image_name:
                needed.add(image_name)
            else:
                notes.append(f"Q{i} imageQuizTemplate-1: missing imageName")

        elif template == "imageQuizTemplate-2":
            image_name = (qd.get("imageName") or "").strip()
            wrong = [str(x).strip() for x in (qd.get("wrongAnswers") or [])]
            if image_name:
                needed.add(image_name)
            else:
                notes.append(f"Q{i} imageQuizTemplate-2: missing imageName")
            if len(wrong) != 3:
                notes.append(
                    f"Q{i} imageQuizTemplate-2: expected 3 wrongAnswers, got {len(wrong)}"
                )
            for w in wrong:
                if w:
                    needed.add(w)

    return needed, notes


def main() -> int:
    level_dirs = sorted(
        d for d in LEVELS_DIR.iterdir() if d.is_dir() and not d.name.startswith("_")
    )

    rows: list[dict] = []
    total_orphan_files = 0
    total_missing_files = 0

    for level_dir in level_dirs:
        questions_path = level_dir / "questions.json"
        in_folder = folder_images(level_dir)

        if not questions_path.exists():
            if in_folder:
                rows.append(
                    {
                        "level": level_dir.name,
                        "orphan_in_folder": sorted(in_folder),
                        "missing_in_folder": [],
                        "notes": ["no questions.json"],
                    }
                )
                total_orphan_files += len(in_folder)
            continue

        needed, notes = collect_question_images(questions_path)

        # Only compare levels that use image quiz templates or have images.
        has_image_quiz = bool(needed)
        if not has_image_quiz and not in_folder:
            continue

        orphan = sorted(in_folder - needed)
        missing = sorted(needed - in_folder)

        if orphan or missing or notes:
            rows.append(
                {
                    "level": level_dir.name,
                    "orphan_in_folder": orphan,
                    "missing_in_folder": missing,
                    "notes": notes,
                }
            )
            total_orphan_files += len(orphan)
            total_missing_files += len(missing)

    lines: list[str] = [
        "# Level image folder audit",
        "",
        "Compares each level folder under `app/assets/quiz-data/levels/` with",
        "`imageQuizTemplate-1` and `imageQuizTemplate-2` entries in `questions.json`.",
        "",
        "- **imageQuizTemplate-1**: only `imageName` must exist as an image file.",
        "- **imageQuizTemplate-2**: `imageName` plus all three `wrongAnswers` must exist as image files.",
        "",
        f"**Levels with mismatches:** {len(rows)}",
        f"**Orphan images (in folder, not referenced):** {total_orphan_files}",
        f"**Missing images (referenced, not in folder):** {total_missing_files}",
        "",
    ]

    if not rows:
        lines.append("No mismatches found.")
    else:
        for row in rows:
            lines.append(f"## {row['level']}")
            lines.append("")
            if row["notes"]:
                lines.append("**Notes:**")
                for n in row["notes"]:
                    lines.append(f"- {n}")
                lines.append("")

            if row["orphan_in_folder"]:
                lines.append(
                    f"**In folder but not in questions ({len(row['orphan_in_folder'])}):**"
                )
                for name in row["orphan_in_folder"]:
                    lines.append(f"- `{name}`")
                lines.append("")

            if row["missing_in_folder"]:
                lines.append(
                    f"**In questions but missing from folder ({len(row['missing_in_folder'])}):**"
                )
                for name in row["missing_in_folder"]:
                    lines.append(f"- `{name}`")
                lines.append("")

            if not row["orphan_in_folder"] and not row["missing_in_folder"] and row["notes"]:
                lines.append("_Structure notes only; image sets match._")
                lines.append("")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    print(f"Levels with mismatches: {len(rows)}")
    print(f"Orphan images: {total_orphan_files}")
    print(f"Missing images: {total_missing_files}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
