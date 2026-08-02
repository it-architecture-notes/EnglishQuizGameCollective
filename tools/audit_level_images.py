#!/usr/bin/env python3
"""Audit level image folders vs imageQuizTemplate-1/2 references in questions.json.

Flavor-aware: every level's questions.json now lives at
{level}/{adults,kids}/questions.json (no root questions.json exists anymore).
Images are migrating the same way but most levels haven't split yet, so image
resolution mirrors the app's own fallback (see image_asset_resolver.dart /
image_quiz_level_loader.dart): prefer {level}/{flavor}/ images if that
subfolder has any, else fall back to the level's root image pool.

Audits both flavors by default (each level's adults/questions.json and
kids/questions.json are checked independently, since they can reference
different image sets) — pass --flavor to check just one.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEVELS_DIR = ROOT / "app" / "assets" / "quiz-data" / "levels"
OUTPUT = ROOT / "cursor-claude-common" / "output" / "image-folder-audit.md"

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}
FLAVORS = ("adults", "kids")


def folder_images(dir_path: Path) -> set[str]:
    if not dir_path.is_dir():
        return set()
    names: set[str] = set()
    for p in dir_path.iterdir():
        if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES:
            names.add(p.stem)
    return names


def resolve_image_dir(level_dir: Path, flavor: str) -> Path:
    """Mirrors the app's own fallback: {level}/{flavor}/ if it has any images,
    else the level root (shared/legacy pool)."""
    flavored = level_dir / flavor
    if folder_images(flavored):
        return flavored
    return level_dir


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


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--flavor",
        choices=FLAVORS,
        default=None,
        help="Audit only this flavor (default: both adults and kids)",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    flavors = (args.flavor,) if args.flavor else FLAVORS

    level_dirs = sorted(
        d for d in LEVELS_DIR.iterdir() if d.is_dir() and not d.name.startswith("_")
    )

    rows: list[dict] = []
    total_orphan_files = 0
    total_missing_files = 0

    for level_dir in level_dirs:
        for flavor in flavors:
            label = f"{level_dir.name}/{flavor}"
            questions_path = level_dir / flavor / "questions.json"
            if not questions_path.is_file():
                continue

            image_dir = resolve_image_dir(level_dir, flavor)
            in_folder = folder_images(image_dir)

            needed, notes = collect_question_images(questions_path)

            # Only compare levels that use image quiz templates or have images.
            if not needed and not in_folder:
                continue

            orphan = sorted(in_folder - needed)
            missing = sorted(needed - in_folder)

            if orphan or missing or notes:
                rows.append(
                    {
                        "level": label,
                        "image_dir": str(image_dir.relative_to(ROOT)),
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
        "Compares each level's `{flavor}/questions.json` (`imageQuizTemplate-1`/`-2`",
        "entries) against the resolved image folder for that flavor — preferring",
        "`{level}/{flavor}/` when it has images, else the level's root pool (same",
        "fallback the app itself uses).",
        "",
        "- **imageQuizTemplate-1**: only `imageName` must exist as an image file.",
        "- **imageQuizTemplate-2**: `imageName` plus all three `wrongAnswers` must exist as image files.",
        "",
        f"**Level/flavor rows with mismatches:** {len(rows)}",
        f"**Orphan images (in folder, not referenced):** {total_orphan_files}",
        f"**Missing images (referenced, not in folder):** {total_missing_files}",
        "",
    ]

    if not rows:
        lines.append("No mismatches found.")
    else:
        for row in rows:
            lines.append(f"## {row['level']}  _(`{row['image_dir']}`)_")
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
    print(f"Level/flavor rows with mismatches: {len(rows)}")
    print(f"Orphan images: {total_orphan_files}")
    print(f"Missing images: {total_missing_files}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
