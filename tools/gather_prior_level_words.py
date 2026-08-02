#!/usr/bin/env python3
"""
Gather English vocabulary already used in WordPairs and translations.json for all
levels that appear **before** a given level in ``game-flow.json``.

This matches the audit skill rule: available word selection excludes ``english_word``
entries from earlier levels' ``translations.json`` and ``english_words`` from
``WordPairs`` rows in ``questions.json``.

Usage:
  python3 tools/gather_prior_level_words.py bedroom
  python3 tools/gather_prior_level_words.py prepositions --format json
  python3 tools/gather_prior_level_words.py bathroom --format csv -o prior-words.csv
  python3 tools/gather_prior_level_words.py bedroom --include-target
  python3 tools/gather_prior_level_words.py bedroom --list-levels

Output (default text): one consumed phrase/word per line (deduplicated, flow order).
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import sys
from pathlib import Path

_WORD_PAIRS_TEMPLATE_IDS = frozenset({"WordPairs", "ConvoTemplate-WordPairs"})

# game-flow iconImageName -> on-disk folder when names differ
_FLOW_ICON_DISK_ALIASES: dict[str, str] = {
    "city-walk": "walking-in-the-city",
}


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def normalize_phrase(text: str) -> str:
    return " ".join((text or "").strip().split())


def load_flow_order(flow_path: Path) -> list[str]:
    """Return level directory names, in game-flow order."""
    return list(load_flow_entries(flow_path).keys())


def load_flow_entries(flow_path: Path) -> dict[str, str]:
    """Return level directory name -> title from game-flow (insertion order).

    Real levels key on ``directoryName`` (schema since the "Big Commit
    Milestone" flow-JSON change). ``reminder`` flow-list entries
    (``kind: "reminder"``, no ``directoryName``) aren't standalone vocabulary
    levels and are skipped — they don't have their own questions.json/
    translations.json to gather words from.
    """
    data = json.loads(flow_path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit(f"Expected JSON array in {flow_path}")
    entries: dict[str, str] = {}
    for entry in data:
        if not isinstance(entry, dict):
            continue
        if entry.get("kind") == "reminder":
            continue
        name = entry.get("directoryName") or entry.get("iconImageName")
        if isinstance(name, str) and name.strip():
            title = entry.get("title")
            entries[name.strip()] = (
                title.strip() if isinstance(title, str) else ""
            )
    return entries


def _dir_with_questions(levels_root: Path, folder_name: str, flavor: str) -> Path | None:
    """Prefer ``{folder_name}/{flavor}/questions.json`` (current adults/kids split
    layout); fall back to ``{folder_name}/questions.json`` directly for any level
    that hasn't been split (legacy/root layout)."""
    levels_root = levels_root.resolve()
    for base in (levels_root / "implemented", levels_root):
        flavored = base / folder_name / flavor
        if (flavored / "questions.json").is_file():
            return flavored.resolve()
        candidate = base / folder_name
        if (candidate / "questions.json").is_file():
            return candidate.resolve()
    return None


def resolve_level_dir(levels_root: Path, icon_name: str, flavor: str = "adults") -> Path | None:
    """Find level folder containing ``questions.json`` for ``iconImageName``,
    preferring the ``flavor`` (``adults``/``kids``) subfolder."""
    icon_name = icon_name.strip()
    levels_root = levels_root.resolve()

    resolved = _dir_with_questions(levels_root, icon_name, flavor)
    if resolved is not None:
        return resolved

    alias = _FLOW_ICON_DISK_ALIASES.get(icon_name)
    if alias:
        resolved = _dir_with_questions(levels_root, alias, flavor)
        if resolved is not None:
            return resolved

    for p in levels_root.rglob("questions.json"):
        if p.parent.name == flavor and p.parent.parent.name == icon_name:
            return p.parent.resolve()
        if p.parent.name == icon_name:
            return p.parent.resolve()

    # Image-only splits on disk: body-parts -> body-parts-1, body-parts-2, ...
    prefix = f"{icon_name}-"
    numbered: list[tuple[int, Path]] = []
    for p in levels_root.rglob("questions.json"):
        parent = p.parent
        is_flavor_split = parent.name in ("adults", "kids")
        if is_flavor_split and parent.name != flavor:
            continue
        level_folder_name = parent.parent.name if is_flavor_split else parent.name
        if not level_folder_name.startswith(prefix):
            continue
        suffix = level_folder_name[len(prefix) :]
        if suffix.isdigit():
            numbered.append((int(suffix), parent))
    if numbered:
        numbered.sort(key=lambda item: item[0])
        return numbered[0][1].resolve()

    return None


def is_image_only_flow_title(title: str) -> bool:
    return "image only" in (title or "").lower()


def resolve_prior_level_dirs(
    prior_names: list[str],
    *,
    levels_root: Path,
    flow_path: Path,
    flavor: str = "adults",
) -> tuple[list[tuple[str, Path]], list[str]]:
    """
    Map prior flow icon names to level folders (preferring ``flavor``'s subfolder).

    Skips flow entries titled ``… Image only`` when no folder exists (no warning).
    Returns (prior_dirs, missing_icon_names_still_unresolved).
    """
    flow_titles = load_flow_entries(flow_path)
    prior_dirs: list[tuple[str, Path]] = []
    missing: list[str] = []
    for name in prior_names:
        level_dir = resolve_level_dir(levels_root, name, flavor)
        if level_dir is None:
            if is_image_only_flow_title(flow_titles.get(name, "")):
                continue
            missing.append(name)
            continue
        prior_dirs.append((name, level_dir))
    return prior_dirs, missing


def level_label(level_dir: Path, levels_root: Path) -> str:
    try:
        return level_dir.relative_to(levels_root.resolve()).as_posix()
    except ValueError:
        return level_dir.name


def words_from_translations(path: Path) -> list[str]:
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    lst = data.get("translations_list")
    if not isinstance(lst, list):
        return []
    out: list[str] = []
    for entry in lst:
        if isinstance(entry, dict):
            w = entry.get("english_word")
            if isinstance(w, str) and w.strip():
                out.append(normalize_phrase(w))
    return out


def words_from_word_pairs(path: Path) -> list[str]:
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    rows = data.get("levelQuestions")
    if not isinstance(rows, list):
        return []
    out: list[str] = []
    for item in rows:
        if not isinstance(item, dict):
            continue
        tpl = (item.get("template") or "").strip()
        if tpl not in _WORD_PAIRS_TEMPLATE_IDS:
            continue
        qd = item.get("questionData")
        if not isinstance(qd, dict):
            continue
        raw = qd.get("english_words")
        if isinstance(raw, list):
            for w in raw:
                if isinstance(w, str) and w.strip():
                    out.append(normalize_phrase(w))
    return out


def collect_level_vocabulary(
    level_dir: Path,
    levels_root: Path,
) -> list[tuple[str, str, str]]:
    """
    Return list of (word, level_label, source) where source is
    ``translations`` or ``wordpairs``.
    """
    label = level_label(level_dir, levels_root)
    entries: list[tuple[str, str, str]] = []
    tp = level_dir / "translations.json"
    for w in words_from_translations(tp):
        entries.append((w, label, "translations"))
    qp = level_dir / "questions.json"
    for w in words_from_word_pairs(qp):
        entries.append((w, label, "wordpairs"))
    return entries


def dedupe_entries(
    entries: list[tuple[str, str, str]],
) -> list[tuple[str, str, str]]:
    """Keep first occurrence (flow order); key is case-insensitive phrase."""
    seen: set[str] = set()
    out: list[tuple[str, str, str]] = []
    for word, level, source in entries:
        key = word.lower()
        if key in seen:
            continue
        seen.add(key)
        out.append((word, level, source))
    return out


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    root = repo_root()
    p = argparse.ArgumentParser(
        description="List WordPairs + translations vocabulary from levels before a target level.",
    )
    p.add_argument(
        "level",
        help="Target level iconImageName from game-flow.json (e.g. bedroom, prepositions)",
    )
    p.add_argument(
        "--flow",
        type=Path,
        default=root / "app/assets/data/flow/game-flow.json",
        help="Game flow JSON (default: app/assets/data/flow/game-flow.json)",
    )
    p.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
        help="Root directory containing level folders",
    )
    p.add_argument(
        "--format",
        choices=("text", "json", "csv"),
        default="text",
        help="Output format (default: text — one word/phrase per line)",
    )
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Write to file instead of stdout",
    )
    p.add_argument(
        "--include-target",
        action="store_true",
        help="Include the target level's vocabulary (not only prior levels)",
    )
    p.add_argument(
        "--list-levels",
        action="store_true",
        help="Print prior level paths and exit (no vocabulary)",
    )
    p.add_argument(
        "--flavor",
        choices=("adults", "kids"),
        default="adults",
        help="Read the adults/ or kids/ subfolder's questions.json/translations.json "
        "(default: adults). Falls back to a level's root files if that flavor "
        "subfolder doesn't exist yet.",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    flow_path = args.flow.resolve()
    levels_root = args.levels_root.resolve()
    target = args.level.strip()

    if not flow_path.is_file():
        print(f"error: flow file not found: {flow_path}", file=sys.stderr)
        return 1

    flow_order = load_flow_order(flow_path)
    if target not in flow_order:
        print(
            f"error: level {target!r} not found in {flow_path.name}. "
            f"Known: {', '.join(flow_order[:5])}… ({len(flow_order)} total)",
            file=sys.stderr,
        )
        return 1

    target_idx = flow_order.index(target)
    if args.include_target:
        prior_names = flow_order[: target_idx + 1]
    else:
        prior_names = flow_order[:target_idx]

    prior_dirs, missing = resolve_prior_level_dirs(
        prior_names,
        levels_root=levels_root,
        flow_path=flow_path,
        flavor=args.flavor,
    )

    if args.list_levels:
        for name, d in prior_dirs:
            print(level_label(d, levels_root))
        if missing:
            print(f"\n# missing on disk ({len(missing)}):", file=sys.stderr)
            for m in missing:
                print(f"  {m}", file=sys.stderr)
        return 0

    all_entries: list[tuple[str, str, str]] = []
    for _name, d in prior_dirs:
        all_entries.extend(collect_level_vocabulary(d, levels_root))
    all_entries = dedupe_entries(all_entries)

    if missing:
        print(
            f"# warning: {len(missing)} flow level(s) not found on disk: "
            + ", ".join(missing),
            file=sys.stderr,
        )

    if args.format == "json":
        payload = {
            "target_level": target,
            "prior_level_count": len(prior_dirs),
            "word_count": len(all_entries),
            "words": [
                {"word": w, "level": lev, "source": src}
                for w, lev, src in all_entries
            ],
        }
        text = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    elif args.format == "csv":
        buf = io.StringIO()
        w = csv.writer(buf)
        w.writerow(["word", "level", "source"])
        for word, lev, src in all_entries:
            w.writerow([word, lev, src])
        text = buf.getvalue()
    else:
        text = "\n".join(w for w, _lev, _src in all_entries)
        if all_entries:
            text += "\n"

    if args.output:
        args.output.write_text(text, encoding="utf-8")
        print(f"Wrote {len(all_entries)} words to {args.output}", file=sys.stderr)
    else:
        sys.stdout.write(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
