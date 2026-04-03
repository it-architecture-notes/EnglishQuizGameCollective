#!/usr/bin/env python3
"""Ensure each level folder's questions.json lists every image as imageQuizTemplate-1.

Preserves non-image questions (vocab/grammar) from existing questions.json.
Run from repo root: python3 tools/sync_level_image_questions.py
"""
from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
LEVELS = REPO / "app" / "assets" / "quiz-data" / "levels"
THEME_GROUPS_PATH = REPO / "tools" / "issue18_theme_groups_max10.json"
IMG_EXT = {".png", ".jpg", ".jpeg", ".webp"}


def list_stems(folder: Path) -> list[str]:
    if not folder.is_dir():
        return []
    return sorted(
        f.stem
        for f in folder.iterdir()
        if f.is_file() and f.suffix.lower() in IMG_EXT
    )


def theme_fallback_basenames(folder_name: str) -> list[str]:
    raw = json.loads(THEME_GROUPS_PATH.read_text(encoding="utf-8"))
    for g in raw:
        if folder_name in g:
            acc: list[str] = []
            for k in g:
                acc.extend(list_stems(LEVELS / k))
            return sorted(set(acc))
    return list_stems(LEVELS / folder_name)


def wrong_three(b: str, pool: list[str], folder_name: str) -> list[str]:
    fallback = theme_fallback_basenames(folder_name)
    others = [x for x in pool if x != b]
    if len(others) >= 3:
        return others[:3]
    out = list(others)
    for x in fallback:
        if x != b and x not in out:
            out.append(x)
        if len(out) >= 3:
            break
    if len(out) < 3:
        raise RuntimeError(f"Cannot pick 3 wrong for {b!r} folder={folder_name!r}")
    return out[:3]


def main() -> None:
    for folder in sorted(LEVELS.iterdir()):
        if not folder.is_dir() or folder.name.startswith("."):
            continue
        basenames = sorted(
            f.stem
            for f in folder.iterdir()
            if f.is_file() and f.suffix.lower() in IMG_EXT
        )
        if not basenames:
            continue
        qpath = folder / "questions.json"
        convo: list[dict] = []
        if qpath.is_file():
            data = json.loads(qpath.read_text(encoding="utf-8"))
            for q in data.get("levelQuestions", []):
                if q.get("type") != "image":
                    convo.append(q)
        new_rows: list[dict] = []
        for b in basenames:
            new_rows.append(
                {
                    "type": "image",
                    "template": "imageQuizTemplate-1",
                    "questionData": {
                        "imageName": b,
                        "wrongAnswers": wrong_three(b, basenames, folder.name),
                    },
                }
            )
        out = {"levelQuestions": new_rows + convo}
        qpath.parent.mkdir(parents=True, exist_ok=True)
        qpath.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print(f"{folder.name}: {len(new_rows)} image rows + {len(convo)} convo")


if __name__ == "__main__":
    main()
