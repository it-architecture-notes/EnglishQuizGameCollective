#!/usr/bin/env python3
"""Rename quiz-data level images so filenames match questions.json imageName (truncation + slug fixes)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "app" / "assets" / "quiz-data" / "levels"


def corrupt_stem(image_name: str) -> str:
    s = image_name.strip().replace(" ", "-")
    parts = [p for p in s.split("-") if p]
    res: list[str] = []
    for p in parts:
        if len(p) == 1:
            res.append(p)
        else:
            res.append(p[1:])
    return "-".join(res).lower()


def all_image_names(qpath: Path) -> list[str]:
    data = json.loads(qpath.read_text(encoding="utf-8"))
    out: list[str] = []
    for q in data.get("levelQuestions", []):
        if q.get("type") != "image":
            continue
        im = q.get("questionData", {}).get("imageName", "")
        if im:
            out.append(im)
    return out


def collect_renames() -> list[tuple[Path, Path]]:
    renames: list[tuple[Path, Path]] = []
    for folder in sorted(ROOT.iterdir()):
        if not folder.is_dir():
            continue
        qpath = folder / "questions.json"
        if not qpath.exists():
            continue
        names = all_image_names(qpath)
        for im in names:
            target = folder / f"{im}.png"
            if target.exists():
                continue
            c = corrupt_stem(im)
            candidates = [p for p in folder.glob("*.png") if p.stem.lower() == c]
            if len(candidates) == 1:
                renames.append((candidates[0], target))
                continue
            if len(candidates) > 1:
                raise SystemExit(f"Ambiguous corrupt match in {folder.name}: {im!r} -> {c!r}: {candidates}")
            slug = im.replace(" ", "-")
            slug_path = folder / f"{slug}.png"
            if slug_path.exists() and slug_path != target:
                renames.append((slug_path, target))
                continue
            found = None
            for p in folder.glob("*.png"):
                if p.stem.lower() == slug.lower():
                    found = p
                    break
            if found is not None and found != target:
                renames.append((found, target))
                continue
            # Plum: lum.png or um.png (extra truncation) -> Plum.png
            if im == "Plum":
                for stem in ("lum", "um"):
                    p = folder / f"{stem}.png"
                    if p.exists():
                        renames.append((p, target))
                        break
                else:
                    raise SystemExit(f"Unresolved Plum image in {folder.name}")
                continue
            raise SystemExit(f"Unresolved: {folder.name} imageName={im!r} corrupt={c!r}")

    srcs = {str(a) for a, _ in renames}
    dsts = {str(b) for _, b in renames}
    if srcs & dsts:
        raise SystemExit(f"Rename cycle/overlap: {srcs & dsts}")
    return renames


def fix_plum_typo() -> None:
    p = ROOT / "market-fruits-3" / "questions.json"
    if not p.exists():
        return
    text = p.read_text(encoding="utf-8")
    if "PLum" not in text:
        return
    p.write_text(text.replace("PLum", "Plum"), encoding="utf-8")
    print("Fixed PLum -> Plum in market-fruits-3/questions.json")


def main() -> None:
    dry = "--dry-run" in sys.argv
    fix_plum_typo()
    renames = collect_renames()
    print(f"{'Would rename' if dry else 'Renaming'} {len(renames)} files")
    for src, dst in renames:
        if dry:
            print(f"  {src} -> {dst.name}")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.exists():
                raise SystemExit(f"Target exists: {dst}")
            src.rename(dst)
    if dry:
        print("(dry-run: no changes written)")


if __name__ == "__main__":
    main()
