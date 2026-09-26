#!/usr/bin/env python3
"""
Gather all English vocabulary words from each adults-beginner quiz level under their level titles.

Extracts:
1. `translations.json` -> `translations_list[].english_word`
2. `questions.json` -> `levelQuestions[].questionData.english_words` (from WordPairs questions)

Features:
- Orders levels according to `game-flow-adults-beginner.json` (with any remaining unmapped disk levels appended).
- Grouped by Level Title and Main Level.
- Inverted Word Index: see which level(s) each word appears in.
- Duplicate detection: find words repeated across multiple levels.
- Search filter: lookup specific words/phrases across all levels.
- Multiple export formats: plain text, Markdown, JSON, CSV.

Usage examples:
  python3 tools/gather_adults_beginner_level_words.py
  python3 tools/gather_adults_beginner_level_words.py --format markdown -o all-ai-common/output/adults-beginner-vocab-by-level.md
  python3 tools/gather_adults_beginner_level_words.py --word-index
  python3 tools/gather_adults_beginner_level_words.py --duplicates-only
  python3 tools/gather_adults_beginner_level_words.py --search "ready"
  python3 tools/gather_adults_beginner_level_words.py --format json
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
from collections import defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

_WORD_PAIRS_TEMPLATES = frozenset({"WordPairs", "ConvoTemplate-WordPairs"})

_FLOW_ICON_DISK_ALIASES: dict[str, str] = {
    "city-walk": "walking-in-the-city",
}

GRAMMAR_CATEGORIES: tuple[str, ...] = (
    "Present simple",
    "Present continuous",
    "Past simple",
    "Past continuous",
    "Present perfect",
    "Past participle / passive",
    "Future: will",
    "Future: going to",
    "Modal verbs",
    "Imperative",
    "There is / There are",
)

_PAST_SIMPLE_WORDS = frozenset(
    {
        "was", "were", "went", "came", "got", "made", "said", "took", "saw",
        "gave", "brought", "bought", "felt", "found", "had", "heard", "held",
        "kept", "knew", "left", "lost", "met", "paid", "ran", "sat", "sold",
        "slept", "spoke", "spent", "stood", "taught", "thought", "took", "woke",
        "wrote", "became", "began", "broke", "caught", "drew", "drank", "drove",
        "ate", "fell", "flew", "grew", "hid", "led", "read", "rode", "rose",
        "sang", "sank", "shook", "showed", "stole", "swam", "threw", "wore",
        "won", "worked", "looked", "walked", "talked", "played", "lived", "moved",
        "opened", "closed", "started", "stopped", "helped", "wanted", "needed",
        "liked", "loved", "finished", "waited", "turned", "stayed", "called",
        "arrived", "reached", "picked", "harvested", "decorated", "prepared",
    }
)

_PAST_PARTICIPLES = frozenset(
    {
        "been", "gone", "seen", "done", "taken", "given", "written", "driven",
        "eaten", "broken", "chosen", "fallen", "forgotten", "hidden", "known",
        "left", "lost", "met", "paid", "spoken", "taught", "thought", "thrown",
        "worn", "won", "built", "caught", "felt", "found", "held", "kept", "led",
        "made", "read", "run", "sat", "sent", "slept", "spent", "stood", "told",
        "understood", "become", "come", "grown", "shown", "drawn", "fought",
        "contained", "managed", "promised", "solved", "recorded", "destroyed",
        "accepted", "published", "achieved", "fixed", "organized", "referred",
        "replied", "reached", "woken", "washed", "brushed", "combed",
    }
)

_ADJECTIVE_PARTICIPLES = frozenset(
    {
        "awake", "asleep", "afraid", "bored", "bright", "closed", "comfortable",
        "confused", "dirty", "excited", "fine", "happy", "interested", "late",
        "pleased", "relaxed", "ready", "scared", "sleepy", "tired", "worried",
    }
)

_PRESENT_LEXICAL_VERBS = frozenset(
    {
        "be", "am", "is", "are", "have", "has", "do", "does", "want", "need",
        "like", "live", "go", "get", "wake", "sleep", "feel", "look", "take",
        "wash", "use", "clean", "comb", "brush", "dream", "rest", "turn", "open",
        "show", "know", "hope", "think", "make", "meet", "see", "say", "ring",
        "stand", "stretch", "study", "come", "from",
    }
)


def _english_value(value: Any) -> str | None:
    if isinstance(value, str) and value.strip():
        return normalize_space(value)
    if isinstance(value, dict):
        for key in ("en", "english"):
            candidate = value.get(key)
            if isinstance(candidate, str) and candidate.strip():
                return normalize_space(candidate)
    return None


def _replace_blanks(text: str, answers: list[str]) -> tuple[str, list[str]]:
    remaining = list(answers)

    def replace_one(_: re.Match[str]) -> str:
        return remaining.pop(0) if remaining else "_____"

    return re.sub(r"_{2,}", replace_one, text), remaining


def _question_texts(item: dict[str, Any]) -> list[str]:
    qd = item.get("questionData")
    if not isinstance(qd, dict):
        return []

    raw_answers = qd.get("answers", qd.get("answer"))
    if isinstance(raw_answers, list):
        answers = [str(x).strip() for x in raw_answers if str(x).strip()]
    elif isinstance(raw_answers, str) and raw_answers.strip():
        answers = [raw_answers.strip()]
    else:
        answers = []

    texts: list[str] = []
    for key in ("line1", "line2", "sentence", "words", "correct_order"):
        value = qd.get(key)
        if isinstance(value, list):
            value = " ".join(str(x) for x in value)
        text = _english_value(value)
        if not text:
            continue
        resolved, answers = _replace_blanks(text, answers)
        texts.append(resolved)

    # A sentence answer can itself contain grammar, while a one-word cloze answer
    # is already represented in the resolved sentence above.
    if isinstance(raw_answers, str) and "_" not in raw_answers and " " in raw_answers.strip():
        texts.append(raw_answers.strip())

    for key in (
        "question_enter_audio_text",
        "question_exit_correct_audio_text",
        "question_exit_wrong_audio_text",
    ):
        value = item.get(key)
        values = value if isinstance(value, list) else [value]
        for entry in values:
            text = _english_value(entry)
            if text:
                texts.append(text)

    return list(dict.fromkeys(texts))


def classify_grammar(text: str) -> set[str]:
    t = normalize_space(text).lower()
    if not t:
        return set()
    words = set(re.findall(r"[a-z]+(?:'[a-z]+)?", t))
    categories: set[str] = set()

    if re.search(r"\bthere\s+(?:is|are|was|were)\b", t):
        categories.add("There is / There are")

    if re.search(r"\b(?:can|can't|could|couldn't|should|shouldn't|must|may|might)\b", t):
        categories.add("Modal verbs")

    if re.search(r"\b(?:am|is|are|'m|'s|'re)\s+going\s+to\s+\w+", t):
        categories.add("Future: going to")

    if re.search(r"\bwill\b|\bwon't\b", t):
        categories.add("Future: will")

    if re.search(r"\b(?:was|were)\s+\w+ing\b", t):
        categories.add("Past continuous")

    if re.search(r"\b(?:have|has)\s+(?:" + "|".join(_PAST_PARTICIPLES) + r")\b", t):
        categories.add("Present perfect")

    passive = re.search(
        r"\b(?:am|is|are|was|were|be|been)\s+(?:being\s+)?([a-z]+)\b", t
    )
    if passive and passive.group(1) in _PAST_PARTICIPLES:
        categories.add("Past participle / passive")

    has_present_continuous = bool(
        re.search(r"\b(?:am|is|are|'m|'s|'re)\s+(?:not\s+)?[a-z]+ing\b", t)
    )
    if has_present_continuous:
        if "Future: going to" not in categories:
            categories.add("Present continuous")

    if words & _PAST_SIMPLE_WORDS:
        categories.add("Past simple")

    if re.search(r"^(?:please\s+|just\s+|now\s+)?(?:[a-z]+)\b", t):
        first = t.split()[0]
        if first in {"please", "just", "open", "look", "take", "turn", "go", "show", "wash", "get", "comb", "brush", "remember"}:
            categories.add("Imperative")

    present_aux = re.search(r"\b(?:do|does|have|has)\b", t)
    simple_be = bool(
        re.search(r"\b(?:am|is|are|'m|'s|'re)\b", t)
        and not has_present_continuous
        and "Future: going to" not in categories
    )
    present_lexical = any(
        re.search(
            r"\b(?:i|you|we|they|he|she|it)\s+(?:(?:not|don't|doesn't|really|usually|also|still|just)\s+)*"
            + re.escape(v)
            + r"\b",
            t,
        )
        for v in _PRESENT_LEXICAL_VERBS
        if v not in {"am", "is", "are", "be", "have", "has", "do", "does"}
    )
    if present_aux or simple_be or present_lexical:
        categories.add("Present simple")

    return categories


def extract_grammar_coverage(questions_path: Path) -> dict[str, Any]:
    counts = {category: 0 for category in GRAMMAR_CATEGORIES}
    examples = {category: [] for category in GRAMMAR_CATEGORIES}
    if not questions_path.is_file():
        return {"counts": counts, "examples": examples, "question_count": 0}
    try:
        data = json.loads(questions_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"counts": counts, "examples": examples, "question_count": 0}

    questions = data.get("levelQuestions") if isinstance(data, dict) else []
    if not isinstance(questions, list):
        return {"counts": counts, "examples": examples, "question_count": 0}

    for q_number, item in enumerate(questions, start=1):
        if not isinstance(item, dict) or item.get("template") in {"Chapter", "WordPairs"}:
            continue
        texts = _question_texts(item)
        detected: set[str] = set()
        for text in texts:
            detected.update(classify_grammar(text))
        example_text = " / ".join(texts[:2])[:140]
        for category in detected:
            counts[category] += 1
            if len(examples[category]) < 3:
                examples[category].append(f"Q{q_number}: {example_text}")

    return {
        "counts": counts,
        "examples": examples,
        "question_count": sum(
            1 for item in questions if isinstance(item, dict) and item.get("template") not in {"Chapter", "WordPairs"}
        ),
    }


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def normalize_space(text: str) -> str:
    return " ".join((text or "").strip().split())


@dataclass
class LevelVocabulary:
    directory_name: str
    title: str
    main_level: int | None = None
    flow_order: int | None = None
    translations: list[str] = field(default_factory=list)
    wordpairs: list[str] = field(default_factory=list)
    all_unique_words: list[str] = field(default_factory=list)
    grammar_coverage: dict[str, Any] = field(default_factory=dict)

    @property
    def total_translations(self) -> int:
        return len(self.translations)

    @property
    def total_wordpairs(self) -> int:
        return len(self.wordpairs)

    @property
    def total_unique(self) -> int:
        return len(self.all_unique_words)


def extract_translations(translations_path: Path) -> list[str]:
    if not translations_path.is_file():
        return []
    try:
        data = json.loads(translations_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []

    words: list[str] = []
    items: list[Any] = []

    if isinstance(data, dict):
        if "translations_list" in data and isinstance(data["translations_list"], list):
            items = data["translations_list"]
        elif "translations" in data and isinstance(data["translations"], list):
            items = data["translations"]
    elif isinstance(data, list):
        items = data

    for item in items:
        if isinstance(item, dict):
            w = item.get("english_word") or item.get("word") or item.get("english")
            if isinstance(w, str) and w.strip():
                clean_w = normalize_space(w)
                if clean_w and clean_w not in words:
                    words.append(clean_w)
        elif isinstance(item, str) and item.strip():
            clean_w = normalize_space(item)
            if clean_w and clean_w not in words:
                words.append(clean_w)

    return words


def extract_wordpairs(questions_path: Path) -> list[str]:
    if not questions_path.is_file():
        return []
    try:
        data = json.loads(questions_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []

    questions = data.get("levelQuestions") if isinstance(data, dict) else []
    if not isinstance(questions, list):
        return []

    words: list[str] = []
    for item in questions:
        if not isinstance(item, dict):
            continue
        tpl = item.get("template")
        if tpl not in _WORD_PAIRS_TEMPLATES:
            continue
        qd = item.get("questionData")
        if not isinstance(qd, dict):
            continue
        raw_words = qd.get("english_words")
        if isinstance(raw_words, list):
            for w in raw_words:
                if w is not None and str(w).strip():
                    clean_w = normalize_space(str(w))
                    if clean_w and clean_w not in words:
                        words.append(clean_w)

    return words


def load_game_flow(flow_path: Path) -> list[dict[str, Any]]:
    if not flow_path.is_file():
        return []
    try:
        data = json.loads(flow_path.read_text(encoding="utf-8"))
        if isinstance(data, list):
            return data
    except (OSError, json.JSONDecodeError):
        pass
    return []


def gather_all_adult_levels(root: Path) -> list[LevelVocabulary]:
    levels_root = root / "app" / "assets" / "quiz-data" / "levels"
    flow_path = root / "app" / "assets" / "data" / "flow" / "game-flow-adults-beginner.json"

    flow_entries = load_game_flow(flow_path)
    processed_dirs: set[str] = set()
    levels: list[LevelVocabulary] = []

    # 1. Process levels defined in game-flow-adults-beginner.json in order
    order_idx = 1
    for entry in flow_entries:
        if not isinstance(entry, dict):
            continue
        if entry.get("kind") == "reminder":
            continue

        raw_name = entry.get("directoryName") or entry.get("iconImageName")
        if not isinstance(raw_name, str) or not raw_name.strip():
            continue

        dir_name = raw_name.strip()
        disk_name = _FLOW_ICON_DISK_ALIASES.get(dir_name, dir_name)
        title = (entry.get("title") or dir_name).strip()
        main_lvl = entry.get("mainLevel")

        level_adult_dir = levels_root / disk_name / "adults-beginner"
        if not level_adult_dir.is_dir():
            # Check without flavor split fallback
            candidate = levels_root / disk_name
            if (candidate / "questions.json").is_file():
                level_adult_dir = candidate

        trans_words = extract_translations(level_adult_dir / "translations.json")
        wp_words = extract_wordpairs(level_adult_dir / "questions.json")

        unique_combined = list(dict.fromkeys(trans_words + wp_words))

        lvl = LevelVocabulary(
            directory_name=disk_name,
            title=title,
            main_level=main_lvl if isinstance(main_lvl, int) else None,
            flow_order=order_idx,
            translations=trans_words,
            wordpairs=wp_words,
            all_unique_words=unique_combined,
            grammar_coverage=extract_grammar_coverage(level_adult_dir / "questions.json"),
        )
        levels.append(lvl)
        processed_dirs.add(disk_name)
        order_idx += 1

    # 2. Collect any remaining disk levels not mentioned in game-flow-adults-beginner.json
    if levels_root.is_dir():
        for d in sorted(levels_root.iterdir()):
            if not d.is_dir() or d.name.startswith("."):
                continue
            if d.name in processed_dirs:
                continue

            adult_dir = d / "adults-beginner"
            target_dir = adult_dir if adult_dir.is_dir() else d
            if (target_dir / "questions.json").is_file() or (target_dir / "translations.json").is_file():
                trans_words = extract_translations(target_dir / "translations.json")
                wp_words = extract_wordpairs(target_dir / "questions.json")
                unique_combined = list(dict.fromkeys(trans_words + wp_words))

                inferred_title = d.name.replace("-", " ").title()
                lvl = LevelVocabulary(
                    directory_name=d.name,
                    title=f"{inferred_title} (Off-Flow)",
                    main_level=None,
                    flow_order=order_idx,
                    translations=trans_words,
                    wordpairs=wp_words,
                    all_unique_words=unique_combined,
                    grammar_coverage=extract_grammar_coverage(target_dir / "questions.json"),
                )
                levels.append(lvl)
                processed_dirs.add(d.name)
                order_idx += 1

    return levels


def build_inverted_word_index(levels: list[LevelVocabulary]) -> dict[str, list[dict[str, Any]]]:
    """Return word -> list of {level_title, directory, in_translations, in_wordpairs}."""
    index: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for lvl in levels:
        trans_set = set(w.lower() for w in lvl.translations)
        wp_set = set(w.lower() for w in lvl.wordpairs)
        for w in lvl.all_unique_words:
            w_lower = w.lower()
            index[w].append({
                "level_title": lvl.title,
                "directory_name": lvl.directory_name,
                "main_level": lvl.main_level,
                "flow_order": lvl.flow_order,
                "in_translations": w_lower in trans_set,
                "in_wordpairs": w_lower in wp_set,
            })
    return dict(sorted(index.items(), key=lambda kv: kv[0].lower()))


# ----------------------------------------------------------------------
# Formatters
# ----------------------------------------------------------------------


def format_text_level_view(levels: list[LevelVocabulary], search_filter: str | None = None) -> str:
    lines: list[str] = []
    lines.append("=" * 80)
    lines.append("  ENGLISH QUIZ GAME — ADULTS-BEGINNER LEVEL VOCABULARY BY LEVEL TITLE")
    lines.append("=" * 80)
    lines.append(f"Total Levels Found: {len(levels)}")
    total_trans = sum(len(l.translations) for l in levels)
    total_wp = sum(len(l.wordpairs) for l in levels)
    lines.append(f"Total Translation Entries: {total_trans} | Total WordPairs Entries: {total_wp}")
    lines.append("=" * 80)
    lines.append("")

    for lvl in levels:
        if search_filter:
            q = search_filter.lower()
            title_match = q in lvl.title.lower() or q in lvl.directory_name.lower()
            matches_trans = [w for w in lvl.translations if q in w.lower()]
            matches_wp = [w for w in lvl.wordpairs if q in w.lower()]
            if not title_match and not matches_trans and not matches_wp:
                continue
            trans_list = lvl.translations if title_match else matches_trans
            wp_list = lvl.wordpairs if title_match else matches_wp
        else:
            trans_list = lvl.translations
            wp_list = lvl.wordpairs

        order_str = f"#{lvl.flow_order:02d}" if lvl.flow_order else "--"
        main_str = f"[Main Level {lvl.main_level}]" if lvl.main_level is not None else ""
        header = f" {order_str} {lvl.title} {main_str} (folder: {lvl.directory_name}) "
        lines.append("-" * 80)
        lines.append(header)
        lines.append("-" * 80)

        # Translations
        lines.append(f"  📝 Translations ({len(trans_list)} words):")
        if trans_list:
            for i, w in enumerate(trans_list, start=1):
                lines.append(f"     {i:2d}. {w}")
        else:
            lines.append("     (none)")

        # WordPairs
        lines.append("")
        lines.append(f"  🔀 WordPairs ({len(wp_list)} words):")
        if wp_list:
            for i, w in enumerate(wp_list, start=1):
                lines.append(f"     {i:2d}. {w}")
        else:
            lines.append("     (none)")

        lines.append("")

    return "\n".join(lines)


def format_markdown_level_view(levels: list[LevelVocabulary], search_filter: str | None = None) -> str:
    lines: list[str] = []
    lines.append("# Adults-Beginner Quiz Levels — Vocabulary and Grammar Coverage\n")
    lines.append(f"**Total Levels**: {len(levels)}  \n")
    total_trans = sum(len(l.translations) for l in levels)
    total_wp = sum(len(l.wordpairs) for l in levels)
    lines.append(f"**Total Translations**: {total_trans} | **Total WordPairs**: {total_wp}\n")
    lines.append("---\n")

    current_main: int | None = object()  # type: ignore

    for lvl in levels:
        if search_filter:
            q = search_filter.lower()
            title_match = q in lvl.title.lower() or q in lvl.directory_name.lower()
            matches_trans = [w for w in lvl.translations if q in w.lower()]
            matches_wp = [w for w in lvl.wordpairs if q in w.lower()]
            if not title_match and not matches_trans and not matches_wp:
                continue
            trans_list = lvl.translations if title_match else matches_trans
            wp_list = lvl.wordpairs if title_match else matches_wp
        else:
            trans_list = lvl.translations
            wp_list = lvl.wordpairs

        if lvl.main_level != current_main and lvl.main_level is not None:
            current_main = lvl.main_level
            lines.append(f"\n## 🏆 Main Level {lvl.main_level}\n")

        order_str = f"#{lvl.flow_order}" if lvl.flow_order else ""
        lines.append(f"### {order_str} {lvl.title} (`{lvl.directory_name}`)\n")
        lines.append(f"#### Translations ({len(trans_list)})")
        lines.append("- " + (", ".join(f"`{w}`" for w in trans_list) if trans_list else "*none*"))
        lines.append(f"#### WordPairs ({len(wp_list)})")
        lines.append("- " + (", ".join(f"`{w}`" for w in wp_list) if wp_list else "*none*"))
        grammar = lvl.grammar_coverage
        counts = grammar.get("counts", {})
        examples = grammar.get("examples", {})
        question_count = grammar.get("question_count", 0)
        lines.append("#### Grammar Coverage")
        lines.append(
            f"*{question_count} answerable questions scanned; counts are per question, and a question may appear in more than one category.*"
        )
        lines.append("| Grammar structure | Questions | Examples |")
        lines.append("| :--- | ---: | :--- |")
        for category in GRAMMAR_CATEGORIES:
            if counts.get(category, 0) == 0:
                continue
            example_text = "; ".join(examples.get(category, [])) or "—"
            lines.append(f"| {category} | {counts.get(category, 0)} | {example_text} |")
        lines.append("")

    return "\n".join(lines)


def format_inverted_index(
    index: dict[str, list[dict[str, Any]]],
    duplicates_only: bool = False,
    search_filter: str | None = None,
    as_markdown: bool = False,
) -> str:
    lines: list[str] = []

    filtered_items: list[tuple[str, list[dict[str, Any]]]] = []
    for word, entries in index.items():
        if duplicates_only and len(entries) < 2:
            continue
        if search_filter and search_filter.lower() not in word.lower():
            continue
        filtered_items.append((word, entries))

    if as_markdown:
        lines.append("# Adults-Beginner Vocabulary — Inverted Word Index (Word → Levels)\n")
        if duplicates_only:
            lines.append("> Showing only words appearing in 2 or more levels (cross-level duplicates).\n")
        lines.append(f"**Total Distinct Words**: {len(filtered_items)}\n")
        lines.append("| Word / Phrase | Levels Count | Levels (Sources) |")
        lines.append("| :--- | :---: | :--- |")
        for word, entries in filtered_items:
            locs: list[str] = []
            for e in entries:
                sources = []
                if e["in_translations"]:
                    sources.append("Trans")
                if e["in_wordpairs"]:
                    sources.append("WordPairs")
                src_str = "+".join(sources)
                locs.append(f"**{e['level_title']}** (`{src_str}`)")
            locs_str = "; ".join(locs)
            lines.append(f"| `{word}` | {len(entries)} | {locs_str} |")
    else:
        lines.append("=" * 80)
        lines.append("  INVERTED VOCABULARY INDEX (Word -> Levels Where Used, adults-beginner)")
        if duplicates_only:
            lines.append("  [FILTER: Showing words appearing in 2+ levels]")
        lines.append("=" * 80)
        lines.append(f"Total Words Listed: {len(filtered_items)}")
        lines.append("=" * 80)
        lines.append("")
        for word, entries in filtered_items:
            dup_tag = f" [USED IN {len(entries)} LEVELS]" if len(entries) > 1 else ""
            lines.append(f"📌 '{word}'{dup_tag}:")
            for e in entries:
                src = []
                if e["in_translations"]:
                    src.append("Translations")
                if e["in_wordpairs"]:
                    src.append("WordPairs")
                src_str = " & ".join(src)
                lines.append(f"   • {e['level_title']} ({e['directory_name']}) -> {src_str}")
            lines.append("")

    return "\n".join(lines)


def format_csv(levels: list[LevelVocabulary]) -> str:
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["flow_order", "main_level", "directory_name", "level_title", "source_type", "english_word"])
    for lvl in levels:
        for w in lvl.translations:
            writer.writerow([lvl.flow_order or "", lvl.main_level or "", lvl.directory_name, lvl.title, "translations", w])
        for w in lvl.wordpairs:
            writer.writerow([lvl.flow_order or "", lvl.main_level or "", lvl.directory_name, lvl.title, "wordpairs", w])
    return output.getvalue()


def format_json(levels: list[LevelVocabulary]) -> str:
    data = [asdict(l) for l in levels]
    return json.dumps(data, indent=2, ensure_ascii=False)


# ----------------------------------------------------------------------
# CLI
# ----------------------------------------------------------------------


def main() -> None:
    root = repo_root()
    default_out_dir = root / "all-ai-common" / "output"

    parser = argparse.ArgumentParser(
        description="Gather all vocabulary words from each adults-beginner quiz level under level titles."
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["text", "markdown", "md", "json", "csv"],
        default="markdown",
        help="Output format (default: markdown)",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=None,
        help="Output file path (default: all-ai-common/output/adults-beginner-words-by-level.<ext>)",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print output directly to console instead of writing to output file.",
    )
    parser.add_argument(
        "--word-index",
        "-w",
        action="store_true",
        help="Show inverted index (which word is used in which level) instead of level view.",
    )
    parser.add_argument(
        "--duplicates-only",
        "-d",
        action="store_true",
        help="Show only words that appear in 2 or more levels (implies --word-index).",
    )
    parser.add_argument(
        "--search",
        "-s",
        type=str,
        help="Filter levels or words matching a substring search.",
    )

    args = parser.parse_args()

    levels = gather_all_adult_levels(root)

    is_md = args.format in ("markdown", "md")
    ext = "md" if is_md else ("json" if args.format == "json" else ("csv" if args.format == "csv" else "txt"))

    if args.duplicates_only or args.word_index:
        index = build_inverted_word_index(levels)
        content = format_inverted_index(
            index,
            duplicates_only=args.duplicates_only,
            search_filter=args.search,
            as_markdown=is_md,
        )
        default_filename = f"adults-beginner-word-index.{ext}"
    else:
        if is_md:
            content = format_markdown_level_view(levels, search_filter=args.search)
        elif args.format == "json":
            content = format_json(levels)
        elif args.format == "csv":
            content = format_csv(levels)
        else:
            content = format_text_level_view(levels, search_filter=args.search)
        default_filename = f"adults-beginner-words-by-level.{ext}"

    if args.stdout:
        print(content)
    else:
        out_path = args.output or (default_out_dir / default_filename)
        if not out_path.is_absolute():
            out_path = (root / out_path).resolve()
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(content, encoding="utf-8")
        
        total_trans = sum(len(l.translations) for l in levels)
        total_wp = sum(len(l.wordpairs) for l in levels)
        print("=" * 80)
        print("  ✅ ADULTS-BEGINNER VOCABULARY GATHERING COMPLETE")
        print("=" * 80)
        print(f"  • Scanned Levels:      {len(levels)}")
        print(f"  • Translation Words:   {total_trans}")
        print(f"  • WordPairs Words:     {total_wp}")
        print(f"  • Saved Output File:   {out_path}")
        print("=" * 80)


if __name__ == "__main__":
    main()
