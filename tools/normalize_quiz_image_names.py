#!/usr/bin/env python3
"""
Normalize quiz level image basenames and questions.json image fields:
- Lowercase slug: segments joined with '-', split on spaces and existing hyphens (e.g. airplane-ticket, iv-drip).

Only updates image questions (imageName + wrongAnswers). Convo answer/distractors are unchanged.
"""
from __future__ import annotations

import json
import re
import shutil
import sys
import uuid
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "app" / "assets" / "quiz-data" / "levels"


def normalize_label(s: str) -> str:
    """Split on whitespace and hyphens; lowercase each segment; join with '-'."""
    parts = [p for p in re.split(r"[\s-]+", s.strip()) if p]
    if not parts:
        return s
    return "-".join(p.lower() for p in parts)


def update_questions_json(path: Path) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    changed = False
    for q in data.get("levelQuestions", []):
        if q.get("type") != "image":
            continue
        qd = q.get("questionData")
        if not isinstance(qd, dict):
            continue
        if "imageName" in qd:
            new_name = normalize_label(qd["imageName"])
            if new_name != qd["imageName"]:
                qd["imageName"] = new_name
                changed = True
        if "wrongAnswers" in qd and isinstance(qd["wrongAnswers"], list):
            new_wrong = [normalize_label(w) for w in qd["wrongAnswers"]]
            if new_wrong != qd["wrongAnswers"]:
                qd["wrongAnswers"] = new_wrong
                changed = True
    if changed:
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return changed


def collect_renames_and_deletes(folder: Path) -> tuple[list[tuple[Path, Path]], list[Path]]:
    """Group PNGs by normalized target; keep one rename, mark extras for deletion."""
    groups: dict[Path, list[Path]] = defaultdict(list)
    for png in folder.glob("*.png"):
        dst = folder / f"{normalize_label(png.stem)}.png"
        groups[dst].append(png)

    renames: list[tuple[Path, Path]] = []
    to_delete: list[Path] = []
    for dst, srcs in groups.items():
        srcs = sorted(srcs, key=lambda p: p.name.lower())
        primary = srcs[0]
        for extra in srcs[1:]:
            to_delete.append(extra)
        if primary.resolve() != dst.resolve():
            renames.append((primary, dst))
    return renames, to_delete


def apply_deletes(paths: list[Path], dry_run: bool) -> None:
    for p in paths:
        if dry_run:
            print(f"  (delete duplicate) {p}")
        else:
            p.unlink(missing_ok=True)


def apply_renames(renames: list[tuple[Path, Path]], dry_run: bool) -> None:
    by_target: dict[Path, list[Path]] = defaultdict(list)
    for src, dst in renames:
        by_target.setdefault(dst, []).append(src)
    bad = {k: v for k, v in by_target.items() if len(v) > 1}
    if bad:
        raise SystemExit(f"Multiple sources map to same target: {bad}")

    tmp_pairs: list[tuple[Path, Path, Path]] = []
    for src, dst in renames:
        tmp = src.with_name(src.stem + f".normalize-{uuid.uuid4().hex}.tmp" + src.suffix)
        tmp_pairs.append((src, tmp, dst))

    if dry_run:
        for src, _, dst in tmp_pairs:
            print(f"  {src.name} -> {dst.name}")
        return

    for src, tmp, dst in tmp_pairs:
        if not src.exists():
            continue
        src.rename(tmp)

    for _, tmp, dst in tmp_pairs:
        if not tmp.exists():
            continue
        if dst.exists() and tmp.resolve() != dst.resolve():
            dst.unlink()
        shutil.move(str(tmp), str(dst))


def main() -> None:
    dry = "--dry-run" in sys.argv
    json_changed = 0

    for qpath in sorted(ROOT.glob("*/questions.json")):
        if dry:
            continue
        if update_questions_json(qpath):
            json_changed += 1
            print(f"Updated {qpath.relative_to(ROOT.parent.parent.parent)}")

    if dry:
        print("Dry-run: skipping JSON writes; preview file operations only.")

    all_renames: list[tuple[Path, Path]] = []
    all_deletes: list[Path] = []
    for folder in sorted(ROOT.iterdir()):
        if not folder.is_dir():
            continue
        r, d = collect_renames_and_deletes(folder)
        all_renames.extend(r)
        all_deletes.extend(d)

    if all_deletes:
        print(f"{'Would delete' if dry else 'Deleting'} {len(all_deletes)} duplicate PNG(s)")
        apply_deletes(all_deletes, dry_run=dry)

    print(f"{'Would rename' if dry else 'Renaming'} {len(all_renames)} image file(s)" + (f"; {json_changed} JSON file(s) updated" if not dry else ""))
    apply_renames(all_renames, dry_run=dry)


if __name__ == "__main__":
    main()
