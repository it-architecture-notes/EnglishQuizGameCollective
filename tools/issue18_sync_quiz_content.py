#!/usr/bin/env python3
"""One-off sync for Issue-18: split oversized level folders, regenerate questions.json.

Run from repo root: python3 tools/issue18_sync_quiz_content.py
"""
from __future__ import annotations

import json
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
LEVELS = REPO / "app" / "assets" / "quiz-data" / "levels"
FLOW_PATH = REPO / "app" / "assets" / "data" / "flow" / "game-flow.json"
PUBSPEC_PATH = REPO / "app" / "pubspec.yaml"
IMG_EXT = {".png", ".jpg", ".jpeg", ".webp"}

PLANNED_CONVO: dict[str, int] = {"kitchen-1": 5}

# Only these folders keep vocabulary/grammar rows; others are image-only (drops copy-paste convo).
CONVO_SOURCES: frozenset[str] = frozenset({"travel-1", "bathroom", "kitchen-1"})

OVERFLOW_DEST: dict[str, str] = {
    "travel-1": "travel-3",
    "bathroom": "bathroom-2",
    "bedroom": "bedroom-2",
    "body-parts": "body-parts-2",
    "dressing-2": "dressing-3",
    "emotions-1": "emotions-3",
    "farm-animals": "farm-animals-2",
    "grocery": "grocery-2",
    "hospital": "hospital-2",
    "kitchen-1": "kitchen-3",
    "kitchen-2": "kitchen-4",
    "living-room": "living-room-2",
    "market-vegetables-1": "market-vegetables-3",
    "market-vegetables-2": "market-vegetables-4",
    "pharmacy": "pharmacy-2",
    "school supplies": "school supplies-2",
    "vehicles": "vehicles-2",
    "wild-animals-1": "wild-animals-3",
    "wild-animals-2": "wild-animals-4",
}

def _load_theme_groups() -> list[list[str]]:
    bundled = REPO / "tools" / "issue18_theme_groups_max10.json"
    if bundled.is_file():
        return json.loads(bundled.read_text(encoding="utf-8"))
    return [
        ["travel-1", "travel-2", "travel-3"],
        ["bathroom", "bathroom-2"],
        ["bedroom", "bedroom-2"],
        ["body-parts", "body-parts-2", "body-parts-3"],
        ["dressing-1", "dressing-2", "dressing-3", "dressing-4"],
        ["emotions-1", "emotions-2", "emotions-3", "emotions-4"],
        ["farm-animals", "farm-animals-2"],
        ["grocery", "grocery-2", "grocery-3"],
        ["hospital", "hospital-2", "hospital-3"],
        ["household-equipment-1", "household-equipment-3"],
        ["household-equipment-2", "household-equipment-4"],
        ["jobs-1", "jobs-2", "jobs-3", "jobs-4", "jobs-5"],
        ["kitchen-1", "kitchen-2", "kitchen-3", "kitchen-4", "kitchen-5"],
        ["living-room", "living-room-2", "living-room-3"],
        ["market-fruits-1", "market-fruits-2", "market-fruits-3"],
        [
            "market-vegetables-1",
            "market-vegetables-2",
            "market-vegetables-3",
            "market-vegetables-4",
        ],
        ["nature-1", "nature-2", "nature-3"],
        ["pharmacy", "pharmacy-2"],
        ["school supplies", "school supplies-2"],
        ["school-1", "school-2", "school-3"],
        ["vehicles", "vehicles-2", "vehicles-3"],
        ["wild-animals-1", "wild-animals-2", "wild-animals-3", "wild-animals-4"],
    ]


THEME_GROUPS: list[list[str]] = _load_theme_groups()

FLOW_INSERT: dict[str, dict] = {
    "travel-1": {"mainLevel": 1, "iconImageName": "travel-3", "title": "Travel 3"},
    "bathroom": {"mainLevel": 1, "iconImageName": "bathroom-2", "title": "Bathroom 2"},
    "bedroom": {"mainLevel": 1, "iconImageName": "bedroom-2", "title": "Bedroom 2"},
    "body-parts": {"mainLevel": 1, "iconImageName": "body-parts-2", "title": "Body Parts 2"},
    "dressing-2": {"mainLevel": 2, "iconImageName": "dressing-3", "title": "Clothes & Style 3"},
    "emotions-1": {"mainLevel": 2, "iconImageName": "emotions-3", "title": "Emotions 3"},
    "farm-animals": {"mainLevel": 2, "iconImageName": "farm-animals-2", "title": "Farm Animals 2"},
    "grocery": {"mainLevel": 3, "iconImageName": "grocery-2", "title": "Grocery 2"},
    "hospital": {"mainLevel": 3, "iconImageName": "hospital-2", "title": "Hospital 2"},
    "kitchen-1": {"mainLevel": 4, "iconImageName": "kitchen-3", "title": "Kitchen 3"},
    "kitchen-2": {"mainLevel": 5, "iconImageName": "kitchen-4", "title": "Kitchen 4"},
    "living-room": {"mainLevel": 5, "iconImageName": "living-room-2", "title": "Living Room 2"},
    "market-vegetables-1": {
        "mainLevel": 5,
        "iconImageName": "market-vegetables-3",
        "title": "Market Vegetables 3",
    },
    "market-vegetables-2": {
        "mainLevel": 6,
        "iconImageName": "market-vegetables-4",
        "title": "Market Vegetables 4",
    },
    "pharmacy": {"mainLevel": 6, "iconImageName": "pharmacy-2", "title": "Pharmacy 2"},
    "school supplies": {
        "mainLevel": 6,
        "iconImageName": "school supplies-2",
        "title": "School Supplies 2",
    },
    "vehicles": {"mainLevel": 7, "iconImageName": "vehicles-2", "title": "Vehicles 2"},
    "wild-animals-1": {
        "mainLevel": 7,
        "iconImageName": "wild-animals-3",
        "title": "Wild Animals 3",
    },
    "wild-animals-2": {
        "mainLevel": 7,
        "iconImageName": "wild-animals-4",
        "title": "Wild Animals 4",
    },
}

PUBSPEC_LINES: dict[str, str] = {
    "travel-3": "    - assets/quiz-data/levels/travel-3/",
    "bathroom-2": "    - assets/quiz-data/levels/bathroom-2/",
    "bedroom-2": "    - assets/quiz-data/levels/bedroom-2/",
    "body-parts-2": "    - assets/quiz-data/levels/body-parts-2/",
    "dressing-3": "    - assets/quiz-data/levels/dressing-3/",
    "emotions-3": "    - assets/quiz-data/levels/emotions-3/",
    "farm-animals-2": "    - assets/quiz-data/levels/farm-animals-2/",
    "grocery-2": "    - assets/quiz-data/levels/grocery-2/",
    "hospital-2": "    - assets/quiz-data/levels/hospital-2/",
    "kitchen-3": "    - assets/quiz-data/levels/kitchen-3/",
    "kitchen-4": "    - assets/quiz-data/levels/kitchen-4/",
    "living-room-2": "    - assets/quiz-data/levels/living-room-2/",
    "market-vegetables-3": "    - assets/quiz-data/levels/market-vegetables-3/",
    "market-vegetables-4": "    - assets/quiz-data/levels/market-vegetables-4/",
    "pharmacy-2": "    - assets/quiz-data/levels/pharmacy-2/",
    "school supplies-2": "    - assets/quiz-data/levels/school supplies-2/",
    "vehicles-2": "    - assets/quiz-data/levels/vehicles-2/",
    "wild-animals-3": "    - assets/quiz-data/levels/wild-animals-3/",
    "wild-animals-4": "    - assets/quiz-data/levels/wild-animals-4/",
}


def list_image_basenames(folder: Path) -> list[str]:
    out: list[str] = []
    if not folder.is_dir():
        return out
    for f in folder.iterdir():
        if f.is_file() and f.suffix.lower() in IMG_EXT:
            out.append(f.stem)
    return sorted(out)


def count_convo_in_json(path: Path) -> int:
    if not path.is_file():
        return 0
    data = json.loads(path.read_text(encoding="utf-8"))
    return sum(
        1 for q in data.get("levelQuestions", []) if q.get("type") in ("vocab", "grammar")
    )


def extract_convo_questions(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return [q for q in data.get("levelQuestions", []) if q.get("type") in ("vocab", "grammar")]


def effective_convo_count(folder_name: str) -> int:
    p = LEVELS / folder_name / "questions.json"
    c = count_convo_in_json(p)
    return max(c, PLANNED_CONVO.get(folder_name, 0))


def theme_fallback_basenames(name: str) -> list[str]:
    for g in THEME_GROUPS:
        if name in g:
            acc: list[str] = []
            for k in g:
                acc.extend(list_image_basenames(LEVELS / k))
            return sorted(set(acc))
    return list_image_basenames(LEVELS / name)


def wrong_three(b: str, pool: list[str], fallback: list[str]) -> list[str]:
    others = [x for x in pool if x != b]
    if len(others) >= 3:
        return others[:3]
    for x in fallback:
        if x != b and x not in others:
            others.append(x)
        if len(others) >= 3:
            break
    if len(others) < 3:
        raise RuntimeError(f"Cannot pick 3 wrong for {b!r} pool={pool!r}")
    return others[:3]


def build_image_questions(basenames: list[str], fallback_pool: list[str]) -> list[dict]:
    return [
        {
            "type": "image",
            "template": "imageQuizTemplate-1",
            "questionData": {"imageName": b, "wrongAnswers": wrong_three(b, basenames, fallback_pool)},
        }
        for b in basenames
    ]


KITCHEN_CONVO = [
    {
        "type": "vocab",
        "template": "ConvoTemplate-1",
        "questionData": {
            "character1": "mike",
            "character2": "sarah",
            "line1": {
                "en": "Should I _____ the oven first?",
                "tr": "Önce fırını _____ mı?",
                "es": "¿Debería _____ el horno primero?",
            },
            "line2": {
                "en": "Yes, set it to 180 degrees.",
                "tr": "Evet, 180 dereceye ayarla.",
                "es": "Sí, ponlo a 180 grados.",
            },
            "answer": "preheat",
            "distractors": ["clean", "open", "fill"],
        },
    },
    {
        "type": "vocab",
        "template": "ConvoTemplate-1",
        "questionData": {
            "character1": "mike",
            "character2": "sarah",
            "line1": {
                "en": "How long should I let the soup _____?",
                "tr": "Çorbayı ne kadar _____ bırakmalıyım?",
                "es": "¿Cuánto tiempo debo dejar _____ la sopa?",
            },
            "line2": {
                "en": "About twenty minutes on low heat.",
                "tr": "Kısık ateşte yaklaşık yirmi dakika.",
                "es": "Unos veinte minutos a fuego lento.",
            },
            "answer": "simmer",
            "distractors": ["bake", "freeze", "taste"],
        },
    },
    {
        "type": "vocab",
        "template": "ConvoTemplate-1",
        "questionData": {
            "character1": "mike",
            "character2": "sarah",
            "line1": {
                "en": "Can you _____ the onions for me?",
                "tr": "Soğanları benim için _____ misin?",
                "es": "¿Puedes _____ las cebollas para mí?",
            },
            "line2": {
                "en": "Sure, I'll do it right away.",
                "tr": "Tabii, hemen yapayım.",
                "es": "Claro, lo hago ahora mismo.",
            },
            "answer": "chop",
            "distractors": ["boil", "bake", "serve"],
        },
    },
    {
        "type": "grammar",
        "template": "ConvoTemplate-1",
        "questionData": {
            "character1": "mike",
            "character2": "sarah",
            "line1": {
                "en": "_____ you making enough food for everyone?",
                "tr": "Herkes için yeterince yemek yapıyor _____?",
                "es": "¿_____ cocinando suficiente comida para todos?",
            },
            "line2": {
                "en": "Yes, I made extra just in case.",
                "tr": "Evet, ihtimale karşı fazladan yaptım.",
                "es": "Sí, hice de más por si acaso.",
            },
            "answer": "Are",
            "distractors": ["Is", "Do", "Have"],
        },
    },
    {
        "type": "grammar",
        "template": "ConvoTemplate-1",
        "questionData": {
            "character1": "mike",
            "character2": "sarah",
            "line1": {
                "en": "You _____ wash your hands before cooking.",
                "tr": "Yemek yapmadan önce ellerini _____ yıkamalısın.",
                "es": "_____ lavarte las manos antes de cocinar.",
            },
            "line2": {
                "en": "You are absolutely right, I forgot.",
                "tr": "Kesinlikle haklısın, unutmuşum.",
                "es": "Tienes toda la razón, lo olvidé.",
            },
            "answer": "should",
            "distractors": ["could", "would", "might"],
        },
    },
]


def run_splits() -> None:
    for src_name, dst_name in OVERFLOW_DEST.items():
        src = LEVELS / src_name
        dst = LEVELS / dst_name
        convo = effective_convo_count(src_name)
        max_keep = 15 - convo
        basenames = list_image_basenames(src)
        if len(basenames) <= max_keep:
            continue
        to_move = basenames[max_keep:]
        dst.mkdir(parents=True, exist_ok=True)
        for stem in to_move:
            moved = False
            for ext in IMG_EXT:
                f = src / f"{stem}{ext}"
                if f.is_file():
                    shutil.move(str(f), str(dst / f.name))
                    moved = True
                    break
            if not moved:
                raise FileNotFoundError(f"No image file for stem {stem!r} in {src}")
        print(f"Split {src_name}: moved {len(to_move)} -> {dst_name}")


def update_game_flow() -> None:
    rows = json.loads(FLOW_PATH.read_text(encoding="utf-8"))
    for r in rows:
        if r.get("iconImageName") == "living room":
            r["iconImageName"] = "living-room"
    existing = {r["iconImageName"] for r in rows}
    fixed: list[dict] = []
    for r in rows:
        fixed.append(r)
        key = r["iconImageName"]
        if key in FLOW_INSERT:
            ins = FLOW_INSERT[key]
            if ins["iconImageName"] not in existing:
                fixed.append(ins)
                existing.add(ins["iconImageName"])
    FLOW_PATH.write_text(json.dumps(fixed, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Updated game-flow.json (living-room + overflow rows)")


def update_pubspec() -> None:
    text = PUBSPEC_PATH.read_text(encoding="utf-8")
    marker = "    - assets/audio/"
    missing = [line for k, line in sorted(PUBSPEC_LINES.items()) if f"levels/{k}/" not in text]
    if missing:
        text = text.replace(marker, "\n".join(missing) + "\n" + marker)
        PUBSPEC_PATH.write_text(text, encoding="utf-8")
    print("Updated pubspec.yaml")


def write_all_questions_json() -> None:
    for folder in sorted(LEVELS.iterdir()):
        if not folder.is_dir() or folder.name.startswith("."):
            continue
        name = folder.name
        basenames = list_image_basenames(folder)
        qpath = folder / "questions.json"
        fallback = theme_fallback_basenames(name)
        if name == "kitchen-1":
            convo = KITCHEN_CONVO
        elif name in CONVO_SOURCES:
            convo = extract_convo_questions(qpath)
        else:
            convo = []
        if not basenames and not convo:
            continue
        images = build_image_questions(basenames, fallback)
        if len(images) > 10:
            raise RuntimeError(f"{name}: {len(images)} image questions > 10")
        total = len(images) + len(convo)
        if total > 15:
            raise RuntimeError(f"{name}: {total} questions > 15 (max 10 image + 5 convo)")
        qpath.write_text(
            json.dumps({"levelQuestions": images + convo}, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {name}: {len(images)} img + {len(convo)} convo")


def main() -> None:
    run_splits()
    update_game_flow()
    update_pubspec()
    write_all_questions_json()


if __name__ == "__main__":
    main()
