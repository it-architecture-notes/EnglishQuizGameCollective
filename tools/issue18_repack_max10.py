#!/usr/bin/env python3
"""Repack quiz level images so each folder has at most 10 images; add spillover folders as needed.

Run from repo root: python3 tools/issue18_repack_max10.py
"""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
LEVELS = REPO / "app" / "assets" / "quiz-data" / "levels"
FLOW_PATH = REPO / "app" / "assets" / "data" / "flow" / "game-flow.json"
PUBSPEC_PATH = REPO / "app" / "pubspec.yaml"

MAX_IMAGES = 10
IMG_EXT = {".png", ".jpg", ".jpeg", ".webp"}

# Ordered theme groups: all images in the group are flattened, sorted by basename, then cut into chunks of 10.
THEME_GROUPS: list[list[str]] = [
    ["travel-1", "travel-2", "travel-3"],
    ["bathroom", "bathroom-2"],
    ["bedroom", "bedroom-2"],
    ["body-parts", "body-parts-2"],
    ["dressing-1", "dressing-2", "dressing-3"],
    ["emotions-1", "emotions-2", "emotions-3"],
    ["farm-animals", "farm-animals-2"],
    ["grocery", "grocery-2"],
    ["hospital", "hospital-2"],
    ["household-equipment-1"],
    ["household-equipment-2"],
    ["jobs-1", "jobs-2", "jobs-3"],
    ["kitchen-1", "kitchen-2", "kitchen-3", "kitchen-4"],
    ["living-room", "living-room-2"],
    ["market-fruits-1", "market-fruits-2"],
    ["market-vegetables-1", "market-vegetables-2", "market-vegetables-3", "market-vegetables-4"],
    ["nature-1", "nature-2"],
    ["pharmacy", "pharmacy-2"],
    ["school supplies", "school supplies-2"],
    ["school-1", "school-2"],
    ["vehicles", "vehicles-2"],
    ["wild-animals-1", "wild-animals-2", "wild-animals-3", "wild-animals-4"],
]


def list_image_files(folder: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    out: list[Path] = []
    for f in sorted(folder.iterdir()):
        if f.is_file() and f.suffix.lower() in IMG_EXT:
            out.append(f)
    return out


def next_folder_name(seed: str, taken: set[str]) -> str:
    """Allocate a new folder name after `seed` (increment trailing number)."""
    if m := re.match(r"^(.+)-(\d+)$", seed):
        prefix, n = m.group(1), int(m.group(2))
        for k in range(n + 1, n + 80):
            c = f"{prefix}-{k}"
            if c not in taken:
                return c
        raise RuntimeError(f"No slot after {seed}")
    if m := re.match(r"^(.+)\s(\d+)$", seed):
        prefix, n = m.group(1), int(m.group(2))
        for k in range(n + 1, n + 80):
            c = f"{prefix} {k}"
            if c not in taken:
                return c
        raise RuntimeError(f"No slot after {seed}")
    raise RuntimeError(f"Cannot extend folder name: {seed!r}")


def collect_group_files(group: list[str]) -> list[tuple[str, Path]]:
    items: list[tuple[str, Path]] = []
    for name in group:
        for p in list_image_files(LEVELS / name):
            items.append((p.stem, p))
    items.sort(key=lambda x: x[0].lower())
    return items


def repack_group(group: list[str], all_level_names: set[str]) -> list[str]:
    """Move files so each of the returned target folders has <= MAX_IMAGES. Returns target folder names in order."""
    items = collect_group_files(group)
    if not items:
        return []

    stems = [s for s, _ in items]
    chunks: list[list[str]] = []
    for i in range(0, len(stems), MAX_IMAGES):
        chunks.append(stems[i : i + MAX_IMAGES])

    targets = list(group)
    taken = set(all_level_names)
    while len(targets) < len(chunks):
        nxt = next_folder_name(targets[-1], taken)
        targets.append(nxt)
        taken.add(nxt)

    # stem -> list of paths (should be one)
    stem_paths: dict[str, list[Path]] = {}
    for stem, path in items:
        stem_paths.setdefault(stem, []).append(path)

    # Assign each stem to its target folder
    stem_to_target: dict[str, str] = {}
    idx = 0
    for chunk in chunks:
        tname = targets[idx]
        for stem in chunk:
            stem_to_target[stem] = tname
        idx += 1

    for stem, paths in stem_paths.items():
        target_name = stem_to_target[stem]
        dest_dir = LEVELS / target_name
        dest_dir.mkdir(parents=True, exist_ok=True)
        for src in paths:
            if src.parent.resolve() == dest_dir.resolve():
                continue
            dest = dest_dir / src.name
            if dest.resolve() != src.resolve():
                shutil.move(str(src), str(dest))

    # Only folders that actually hold a chunk (last chunk may have <10 images)
    return targets[: len(chunks)]


def flow_meta(rows: list[dict]) -> dict[str, dict]:
    return {r["iconImageName"]: dict(r) for r in rows}


def main_level_for(name: str, group: list[str], meta: dict[str, dict]) -> int:
    if name in meta:
        return int(meta[name]["mainLevel"])
    try:
        idx = group.index(name)
    except ValueError:
        idx = 0
    for j in range(idx - 1, -1, -1):
        if group[j] in meta:
            return int(meta[group[j]]["mainLevel"])
    for j in range(idx + 1, len(group)):
        if group[j] in meta:
            return int(meta[group[j]]["mainLevel"])
    return 1


def title_for_new_folder(name: str) -> str:
    if " " in name and re.search(r"\s\d+$", name):
        return name.title()
    return name.replace("-", " ").title()


def rebuild_flow(final_targets_per_group: list[list[str]], old_rows: list[dict]) -> list[dict]:
    meta = flow_meta(old_rows)
    new_rows: list[dict] = []
    for group in final_targets_per_group:
        if not group:
            continue
        for name in group:
            m = meta.get(name)
            ml = main_level_for(name, group, meta)
            if m:
                new_rows.append(
                    {
                        "mainLevel": m["mainLevel"],
                        "iconImageName": name,
                        "title": m["title"],
                    }
                )
            else:
                new_rows.append(
                    {
                        "mainLevel": ml,
                        "iconImageName": name,
                        "title": title_for_new_folder(name),
                    }
                )
    return new_rows


def sync_pubspec_all_levels() -> None:
    """Ensure every directory under levels/ is listed in pubspec (sorted block before assets/audio)."""
    marker = "    - assets/audio/"
    dirs = sorted(
        d.name
        for d in LEVELS.iterdir()
        if d.is_dir() and not d.name.startswith(".")
    )
    lines = [f"    - assets/quiz-data/levels/{name}/" for name in dirs]
    text = PUBSPEC_PATH.read_text(encoding="utf-8")
    start = text.find("    - assets/quiz-data/levels/")
    end = text.find(marker)
    if start == -1 or end == -1:
        raise RuntimeError("pubspec markers not found")
    new_block = "\n".join(lines) + "\n"
    text = text[:start] + new_block + text[end:]
    PUBSPEC_PATH.write_text(text, encoding="utf-8")
    print(f"pubspec: {len(lines)} level folders")


def main() -> None:
    old_flow = json.loads(FLOW_PATH.read_text(encoding="utf-8"))
    all_names = {d.name for d in LEVELS.iterdir() if d.is_dir() and not d.name.startswith(".")}

    final_groups: list[list[str]] = []
    for group in THEME_GROUPS:
        present = [g for g in group if (LEVELS / g).is_dir()]
        if not present:
            continue
        targets = repack_group(present, all_names)
        for t in targets:
            all_names.add(t)
        final_groups.append(targets)
        print(f"Group {present[0]}… -> {targets} (counts: {[len(list_image_files(LEVELS / t)) for t in targets]})")

    new_flow = rebuild_flow(final_groups, old_flow)
    FLOW_PATH.write_text(json.dumps(new_flow, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"game-flow.json: {len(new_flow)} entries")

    sync_pubspec_all_levels()

    # Emit theme groups for issue18_sync_quiz_content THEME_GROUPS sync (optional manual)
    out = REPO / "tools" / "issue18_theme_groups_max10.json"
    out.write_text(json.dumps(final_groups, indent=2), encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
