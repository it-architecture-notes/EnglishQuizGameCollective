#!/usr/bin/env python3
"""Phase-1 granular activity image quizzes (consolidated plan).

Default: curated-60 manifest, images from _image-pool/, rewrite game-flow + main-levels,
append pubspec entries.

Run from repo root:
  python3 tools/build_activity_quizzes_phase1.py
  python3 tools/build_activity_quizzes_phase1.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import random
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
POOL = REPO / "app" / "assets" / "quiz-data" / "_image-pool"
LEVELS = REPO / "app" / "assets" / "quiz-data" / "levels"
FLOW = REPO / "app" / "assets" / "data" / "flow" / "game-flow.json"
MAIN_LEVELS = REPO / "app" / "assets" / "data" / "flow" / "game-flow-main-levels.json"
PUBSPEC = REPO / "app" / "pubspec.yaml"

IMG_EXT = {".png", ".jpg", ".jpeg", ".webp"}

# (slug, title, main_level) — order is canonical (consolidated plan).
CURATED_ACTIVITIES: list[tuple[str, str, int]] = [
    ("waking-up", "Waking Up", 1),
    ("brushing-teeth", "Brushing Teeth", 1),
    ("taking-a-shower", "Taking a Shower", 1),
    ("getting-dressed", "Getting Dressed", 1),
    ("eating-breakfast", "Eating Breakfast", 1),
    ("making-the-bed", "Making the Bed", 2),
    ("packing-a-lunch", "Packing a Lunch", 2),
    ("feeding-a-pet", "Feeding a Pet", 2),
    ("walking-the-dog", "Walking the Dog", 2),
    ("getting-ready-for-bed", "Getting Ready for Bed", 2),
    ("doing-laundry", "Doing Laundry", 3),
    ("washing-dishes", "Washing Dishes", 3),
    ("taking-out-the-trash", "Taking Out the Trash", 3),
    ("vacuuming-the-house", "Vacuuming the House", 3),
    ("making-dinner", "Making Dinner", 3),
    ("setting-the-table", "Setting the Table", 4),
    ("clearing-the-table", "Clearing the Table", 4),
    ("watering-plants", "Watering Plants", 4),
    ("making-coffee-or-tea", "Making Coffee or Tea", 4),
    ("watching-tv", "Watching TV", 4),
    ("grocery-shopping", "Grocery Shopping", 5),
    ("at-the-gas-station", "At the Gas Station", 5),
    ("at-the-park", "At the Park", 5),
    ("eating-at-a-restaurant", "Eating at a Restaurant", 5),
    ("at-the-post-office", "At the Post Office", 5),
    ("at-the-bank", "At the Bank", 6),
    ("at-the-pharmacy", "At the Pharmacy", 6),
    ("visiting-the-doctor", "Visiting the Doctor", 6),
    ("at-the-dentist", "At the Dentist", 6),
    ("exercising", "Exercising", 6),
    ("going-to-work", "Going to Work", 7),
    ("school-day", "School Day", 7),
    ("packing-school-bag", "Packing School Bag", 7),
    ("at-the-airport", "At the Airport", 7),
    ("driving-around-town", "Driving Around Town", 7),
    ("cooking-at-home", "Cooking at Home", 8),
    ("baking-at-home", "Baking at Home", 8),
    ("at-the-farmers-market", "At the Farmer's Market", 8),
    ("on-the-farm", "On the Farm", 8),
    ("wildlife-watching", "Wildlife Watching", 8),
    ("relaxing-at-home", "Relaxing at Home", 9),
    ("reading-at-home", "Reading at Home", 9),
    ("playing-with-pets", "Playing with Pets", 9),
    ("home-repairs", "Home Repairs", 9),
    ("gardening-at-home", "Gardening at Home", 9),
    ("at-the-coffee-shop", "At the Coffee Shop", 10),
    ("city-walk", "City Walk", 10),
    ("at-the-zoo", "At the Zoo", 10),
    ("bird-watching", "Bird Watching", 10),
    ("exploring-nature", "Exploring Nature", 10),
    ("at-the-beach", "At the Beach", 11),
    ("hiking-outdoors", "Hiking Outdoors", 11),
    ("at-the-train-station", "At the Train Station", 11),
    ("checking-the-weather", "Checking the Weather", 11),
    ("body-and-health", "Body and Health", 11),
    ("expressing-emotions", "Expressing Emotions", 12),
    ("going-to-sleep", "Going to Sleep", 12),
    ("personal-hygiene", "Personal Hygiene", 12),
    ("shopping-for-clothes", "Shopping for Clothes", 12),
    ("home-decoration", "Home Decoration", 12),
]

KEYWORD_MAP: dict[str, list[str]] = {
    "waking-up": ["alarm-clock", "bed", "pillow", "blanket", "mattress", "nightstand", "slippers"],
    "brushing-teeth": ["toothbrush", "sink", "comb", "towel", "face-mask", "shaving-razor"],
    "taking-a-shower": ["shower", "bathtub", "bath-mat", "bathrobe", "shower-curtains", "towel"],
    "getting-dressed": ["shoes", "socks", "jeans", "dress", "coat", "belt", "sneakers", "boots", "sweater", "shirt"],
    "eating-breakfast": ["bread", "eggs", "butter", "milk", "plate", "bowl", "fork", "spoon", "frying-pan"],
    "making-the-bed": ["bed", "pillow", "blanket", "duvet-comforter", "bed-frame", "mattress"],
    "packing-a-lunch": ["lunchbox", "backpack", "bread", "food", "bag"],
    "feeding-a-pet": ["cat", "german-shepherd", "rabbit", "fish", "food", "bowl", "duck"],
    "walking-the-dog": ["german-shepherd", "cat", "leash", "bench", "park", "sidewalk"],
    "getting-ready-for-bed": ["slippers", "nightstand", "blanket", "pillow", "bed", "pajamas"],
    "doing-laundry": ["clothes-pin", "iron", "ironing-board", "washing-machine", "tumble-dryer", "laundry-basket"],
    "washing-dishes": ["dish-rack", "dish-soap", "dishwasher", "plate", "sponge", "fork"],
    "taking-out-the-trash": ["garbage-bag", "trash", "broom", "bucket", "mop"],
    "vacuuming-the-house": ["vacuum", "broom", "mop", "bucket", "dust"],
    "making-dinner": ["stove", "frying-pan", "saucepan", "cooking-pot", "spatula", "ladle"],
    "setting-the-table": ["plate", "fork", "spoon", "table-knife", "water-glass", "salt-pepper-shaker"],
    "clearing-the-table": ["plate", "fork", "dish-soap", "dish-rack", "bowl", "trash"],
    "watering-plants": ["plant", "flowers", "vase", "bucket", "grass"],
    "making-coffee-or-tea": ["electric-kettle", "coffee-mug", "milk", "sugar", "toaster"],
    "watching-tv": ["remote-control", "sofa-couch", "tv-stand", "armchair", "picture"],
    "grocery-shopping": ["supermarket", "bread", "eggs", "milk", "cheese", "grocery", "shopping-cart"],
    "at-the-gas-station": ["gas-station", "air-pump", "fuel", "car", "pump"],
    "at-the-park": ["bench", "fountain", "playground", "swing", "grass", "flowers"],
    "eating-at-a-restaurant": ["restaurant", "fork", "plate", "menu", "waiter", "chef"],
    "at-the-post-office": ["post-office", "stamp", "letter", "package", "mailbox"],
    "at-the-bank": ["bank", "atm", "money", "cash", "receipt"],
    "at-the-pharmacy": ["pharmacist", "prescription", "drugs", "bandage", "cough-syrup", "antacids"],
    "visiting-the-doctor": ["doctor", "nurse", "thermometer", "hospital-bed", "patient", "stethoscope"],
    "at-the-dentist": ["dentist", "tooth", "toothbrush", "scale", "gauze", "prescription"],
    "exercising": ["gym", "muscle", "heart", "knee", "leg", "dumbbell"],
    "going-to-work": ["briefcase", "tie", "bus", "train", "office", "accountant", "engineer"],
    "school-day": ["classroom", "whiteboard", "teacher", "desk-chair", "backpack", "bulletin-board"],
    "packing-school-bag": ["backpack", "binder", "pencil", "pen", "notebook", "crayons", "ruler"],
    "at-the-airport": ["airplane-ticket", "passport", "plane", "security-check", "luggage-trolley", "check-in-counter"],
    "driving-around-town": ["car", "bus", "traffic-light", "crosswalk", "road", "skyscraper"],
    "cooking-at-home": ["stove", "cooking-pot", "frying-pan", "apron", "ladle", "spatula"],
    "baking-at-home": ["apron", "baking-tray", "bowl", "rolling-pin", "whisk-beater", "oven-mitt"],
    "at-the-farmers-market": ["apple", "strawberry", "carrot", "tomato", "lettuce", "orange", "mango"],
    "on-the-farm": ["cow", "horse", "pig", "chicken", "sheep", "tractor", "goat"],
    "wildlife-watching": ["deer", "fox", "squirrel", "owl", "eagle", "bird", "butterfly"],
    "relaxing-at-home": ["sofa-couch", "armchair", "remote-control", "pillow", "bookshelf", "fireplace"],
    "reading-at-home": ["armchair", "bookshelf", "sofa-couch", "coffee-table", "floor-lamp"],
    "playing-with-pets": ["cat", "german-shepherd", "rabbit", "fish", "duck", "hamster"],
    "home-repairs": ["hammer", "screwdriver", "drill", "ladder", "pliers", "measure-tape"],
    "gardening-at-home": ["flowers", "plant", "grass", "rake", "bucket"],
    "at-the-coffee-shop": ["cafe", "coffee-mug", "electric-kettle", "bakery", "bookstore"],
    "city-walk": ["skyscraper", "crosswalk", "traffic-light", "bench", "fountain", "sidewalk"],
    "at-the-zoo": ["gorilla", "hippo", "elephant", "rhinoceros", "tiger", "giraffe", "lion"],
    "bird-watching": ["parrot", "owl", "eagle", "crow", "swan", "pigeon", "seagull"],
    "exploring-nature": ["mountain", "forest", "river", "lake", "rocks", "waterfall"],
    "at-the-beach": ["ocean", "sea", "beach", "sand", "island", "crab", "boat"],
    "hiking-outdoors": ["mountain", "forest", "river", "rocks", "lake", "fog"],
    "at-the-train-station": ["train", "subway", "tram", "bus", "bus-stop"],
    "checking-the-weather": ["clouds", "lightning", "rain", "rainbow", "hail", "snow"],
    "body-and-health": ["head", "heart", "knee", "leg", "muscle", "stomach", "back"],
    "expressing-emotions": ["happy", "sad", "angry", "scared", "surprised", "nervous", "bored"],
    "going-to-sleep": ["bed", "blanket", "nightstand", "pillow", "slippers", "moon"],
    "personal-hygiene": ["bathtub", "shower", "sink", "toothbrush", "soap", "towel"],
    "shopping-for-clothes": ["shoes", "jacket", "jeans", "dress", "handbag", "sunglasses", "scarf"],
    "home-decoration": ["vase", "picture", "curtains", "mirror", "plant", "wall-clock", "cushion-pillows"],
}

MAIN_LEVEL_TITLES: list[tuple[int, str]] = [
    (1, "Saving a Puppy"),
    (2, "Help the Old Lady with Her Errands"),
    (3, "Taking Care of Little Timmy"),
    (4, "Cooking for the Whole Family"),
    (5, "A Day in the Big City"),
    (6, "Adventures in the Countryside"),
    (7, "A Week at the Office"),
    (8, "Farm Life and Wild Friends"),
    (9, "Home Sweet Home"),
    (10, "The City Explorer"),
    (11, "Into the Great Outdoors"),
    (12, "A Full Life"),
]


def load_pool_files() -> list[Path]:
    return sorted(
        p for p in POOL.iterdir() if p.is_file() and p.suffix.lower() in IMG_EXT
    )


def score_stem_for_keywords(stem: str, keywords: list[str]) -> int | None:
    """Match whole stem or hyphen tokens only (avoid 'plant' -> 'eggplant')."""
    s = stem.lower()
    segs = set(s.split("-"))
    best: int | None = None
    for kw in keywords:
        k = kw.lower()
        if s == k:
            rank = 0
        elif k in segs:
            rank = 1
        elif s.startswith(k + "-") or s.endswith("-" + k) or f"-{k}-" in s:
            rank = 2
        else:
            continue
        best = rank if best is None else min(best, rank)
    return best


def pick_images_for_slug(
    slug: str, pool_files: list[Path], max_images: int = 6
) -> list[Path]:
    keywords = KEYWORD_MAP.get(slug, [])
    if not keywords:
        return []
    scored: list[tuple[int, str, Path]] = []
    for p in pool_files:
        stem = p.stem
        r = score_stem_for_keywords(stem, keywords)
        if r is not None:
            scored.append((r, stem.lower(), p))
    scored.sort(key=lambda t: (t[0], t[1]))
    out: list[Path] = []
    seen: set[str] = set()
    for _r, _ls, p in scored:
        if p.stem not in seen:
            if slug == "playing-with-pets" and "market" in p.stem.lower():
                continue
            seen.add(p.stem)
            out.append(p)
        if len(out) >= max_images:
            break
    return out


def pool_stems_matching_keywords(
    pool_files: list[Path], keywords: list[str]
) -> list[str]:
    stems: list[str] = []
    seen: set[str] = set()
    for p in pool_files:
        if score_stem_for_keywords(p.stem, keywords) is not None and p.stem not in seen:
            seen.add(p.stem)
            stems.append(p.stem)
    return stems


def wrong_answers_for(
    image_stem: str,
    folder_stems: list[str],
    keywords: list[str],
    pool_files: list[Path],
) -> list[str]:
    others = [s for s in folder_stems if s != image_stem]
    random.shuffle(others)
    picked = others[:3]
    if len(picked) >= 3:
        return picked
    pool_alt = [s for s in pool_stems_matching_keywords(pool_files, keywords) if s != image_stem]
    random.shuffle(pool_alt)
    for s in pool_alt:
        if s not in picked:
            picked.append(s)
        if len(picked) >= 3:
            break
    if len(picked) < 3:
        all_stems = sorted({p.stem for p in pool_files} - {image_stem})
        random.shuffle(all_stems)
        for s in all_stems:
            if s not in picked:
                picked.append(s)
            if len(picked) >= 3:
                break
    return picked[:3]


def write_questions_json(
    slug: str, stems: list[str], pool_files: list[Path], dest: Path
) -> None:
    keywords = KEYWORD_MAP.get(slug, [])
    rows: list[dict] = []
    for stem in stems:
        wa = wrong_answers_for(stem, stems, keywords, pool_files)
        rows.append(
            {
                "type": "image",
                "template": "imageQuizTemplate-1",
                "questionData": {"imageName": stem, "wrongAnswers": wa},
            }
        )
    dest.write_text(
        json.dumps({"levelQuestions": rows}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def sync_folder_images(
    slug: str, selected: list[Path], dry_run: bool
) -> list[str]:
    folder = LEVELS / slug
    if not dry_run:
        folder.mkdir(parents=True, exist_ok=True)
    want_stems = {p.stem for p in selected}
    if folder.is_dir() and not dry_run:
        for f in folder.iterdir():
            if f.suffix.lower() not in IMG_EXT:
                continue
            if f.stem not in want_stems:
                f.unlink()
    stems_out: list[str] = []
    for src in selected:
        stems_out.append(src.stem)
        if dry_run:
            continue
        dest = folder / src.name
        shutil.copy2(src, dest)
    return stems_out


def append_pubspec_slugs(slugs: list[str], dry_run: bool) -> None:
    text = PUBSPEC.read_text(encoding="utf-8")
    missing = [s for s in slugs if f"assets/quiz-data/levels/{s}/" not in text]
    if not missing:
        return
    block = "".join(f"    - assets/quiz-data/levels/{s}/\n" for s in missing)
    if dry_run:
        print(f"[dry-run] would add {len(missing)} pubspec asset lines")
        return
    anchor = "    - assets/audio/\n"
    if anchor in text:
        text = text.replace(anchor, block + anchor, 1)
    else:
        text = text.rstrip() + "\n" + block
    PUBSPEC.write_text(text, encoding="utf-8")


def run_curated60(*, dry_run: bool) -> None:
    random.seed(42)
    pool_files = load_pool_files()
    if not pool_files:
        raise SystemExit(f"No images in {POOL}")

    flow_entries: list[dict] = []
    pubspec_slugs: list[str] = []
    skipped: list[str] = []

    for slug, title, ml in CURATED_ACTIVITIES:
        selected = pick_images_for_slug(slug, pool_files)
        if not selected:
            print(f"WARN skip {slug}: 0 pool matches for keywords")
            skipped.append(slug)
            continue
        print(f"{slug}: {len(selected)} images -> {[p.stem for p in selected]}")
        stems = sync_folder_images(slug, selected, dry_run)
        if not dry_run:
            write_questions_json(slug, stems, pool_files, LEVELS / slug / "questions.json")
        flow_entries.append(
            {"mainLevel": ml, "iconImageName": slug, "title": title}
        )
        pubspec_slugs.append(slug)

    if dry_run:
        print(f"[dry-run] flow entries: {len(flow_entries)}, skipped: {skipped}")
        return

    FLOW.write_text(
        json.dumps(flow_entries, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    MAIN_LEVELS.write_text(
        json.dumps(
            [{"mainLevel": n, "title": t} for n, t in MAIN_LEVEL_TITLES],
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )
    append_pubspec_slugs(pubspec_slugs, dry_run=False)
    print(f"Wrote {FLOW} ({len(flow_entries)} sub-levels)")
    print(f"Wrote {MAIN_LEVELS} (12 main levels)")
    if skipped:
        print(f"Skipped (no flow row): {skipped}")


def run_full(*, dry_run: bool) -> None:
    print(
        "--mode full (activities.txt merge) is not implemented in this build. "
        "Use --mode curated60 per consolidated Phase-1 default.",
        file=sys.stderr,
    )
    raise SystemExit(2)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--mode",
        choices=("curated60", "full"),
        default="curated60",
        help="curated60: 12x5 plan only; full: curated + activities.txt extras",
    )
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if args.mode == "curated60":
        run_curated60(dry_run=args.dry_run)
    else:
        run_full(dry_run=args.dry_run)


if __name__ == "__main__":
    main()
