#!/usr/bin/env python3
"""
Generate tables for one activity level: questions from questions.json and, when
present, translations from translations.json in the same folder.

Usage:
  python3 tools/generate_single_level_questions_table.py \\
    app/assets/quiz-data/levels/greetings

  python3 tools/generate_single_level_questions_table.py greetings

  # Excel-friendly tab-separated (open in Excel / Google Sheets)
  python3 tools/generate_single_level_questions_table.py \\
    app/assets/quiz-data/levels/basic-sentences --format tsv

  # Spreadsheet-friendly comma-separated
  python3 tools/generate_single_level_questions_table.py \\
    app/assets/quiz-data/levels/basic-sentences --format csv

  # Browser: bordered cells, easy to read (recommended for wide columns)
  python3 tools/generate_single_level_questions_table.py \\
    app/assets/quiz-data/levels/greetings --format html

Output (default --format html):
  cursor-claude-common/output/<level-name>-questions.<ext>
  cursor-claude-common/output/prior-words-by-type.md
    (always this filename; overwritten for the selected level — prior flow
    vocabulary grouped by verb / adjective / adverb / etc.)

Also refreshes ``cursor-claude-common/references/final words/*.csv`` (including
``langeek-500-most-common-nouns.csv``, and ``common-verbs.csv``) and marks the Oxford 3000 list — same as
``tools/update_final_word_counts_from_levels.py``. Use ``--skip-final-words`` to
skip that step.

Before writing output, every question is checked against template rules from
`page-designs-and-templates.md` and `app/lib/models/level_config.dart` (required
fields, counts, Cloze blank/answer alignment — blanks may use trailing `.` `!`
`?` etc. on the same token — WordPairs pair count, split audio pairing,
translation fields not misplaced at question root). Any violation
prints all errors and exits with code 1.

Questions table columns:
  - English (translate): english_word values from translations.json that appear in that
    question's prompt/sentence text or answer(s) — full phrase, verb stem, or partial
    content-word overlap (e.g. "to ask a question" ↔ "Teacher asks an easy question");
    for **WordPairs**, all `english_words` that have an embedded `translations` row;
    excludes distractors and wrongAnswers
  - Audio: top-level audio_file, audio_file1, audio_file2 when present

Template summary: a small table with one row per template supported by the game
(`_KNOWN_TEMPLATES` / `level_config.dart`), and how many questions in this level
use that exact `template` string (0 if unused). In HTML output this table appears
after questions and translations; in Markdown / TSV / CSV it appears before the
questions table.

Translations table (only if translations.json exists and has translations_list):
  - #: row index
  - English word: english_word
  - One column per locale code found across all rows (sorted), values from translations[locale]

HTML only: between translations and template counts, a compact **question summary**
table with columns `#`, Line 1, Line 2, Answer, Distractors (distractors or
wrongAnswers from questionData; empty when a template has none).

HTML only: after template counts, a **Word frequency** table for strings in
`questions.json` except: each question’s `template` and `audio_file` /
`audio_file1` / `audio_file2` fields, `questionData.translations` (**WordPairs**
only), `questionData.distractors`, and `questionData.wrongAnswers`. Other strings
use the same token rule as
`tools/update_final_word_counts_from_levels.py` (`[a-z0-9]+(?:[-'][a-z0-9]+)*`,
case-insensitive, lowercased). Sorted by count descending, then word.

HTML only: in the questions table, **English (translate)** entries that appear in
more than one question row (or twice in the same cell) are shown in **red**.
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

_TOOLS_DIR = Path(__file__).resolve().parent
if str(_TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOLS_DIR))

try:
    from gather_prior_level_words import (
        collect_level_vocabulary,
        dedupe_entries,
        load_flow_order,
        resolve_prior_level_dirs,
    )
except ImportError:  # pragma: no cover
    collect_level_vocabulary = None  # type: ignore[misc, assignment]
    dedupe_entries = None  # type: ignore[misc, assignment]
    load_flow_order = None  # type: ignore[misc, assignment]
    resolve_prior_level_dirs = None  # type: ignore[misc, assignment]

try:
    from update_final_word_counts_from_levels import refresh_final_word_references
except ImportError:  # pragma: no cover
    refresh_final_word_references = None  # type: ignore[misc, assignment]

# final words/*.csv filename -> coarse word-type label for prior-vocabulary grouping
_FINAL_CSV_WORD_TYPES: dict[str, str] = {
    "verbs-400.csv": "verb",
    "common-verbs.csv": "verb",
    "adjectives-300.csv": "adjective",
    "adverbs-150.csv": "adverb",
    "prepositions.csv": "preposition",
    "conjunctions.csv": "conjunction",
    "auxiliaries.csv": "auxiliary",
    "langeek-500-most-common-nouns.csv": "noun",
}

_PRIOR_TYPE_SECTION_ORDER = (
    "verb",
    "noun",
    "adjective",
    "adverb",
    "preposition",
    "conjunction",
    "auxiliary",
    "other",
)

TABLE_HEADERS = [
    "#",
    "Template",
    "Line 1 / Prompt",
    "Line 2",
    "Answer",
    "English (translate)",
    "Audio",
]

# Column index in questions table rows for English (translate) highlighting.
_ENGLISH_TRANSLATE_COL = TABLE_HEADERS.index("English (translate)")

# Templates accepted by app/lib/models/level_config.dart _parseQuestion switch.
_KNOWN_TEMPLATES = frozenset(
    {
        "imageQuizTemplate-1",
        "imageQuizTemplate-2",
        "ConvoTemplate-1",
        "AppearDisappear",
        "ClozeSequence",
        "SentenceBuilder",
        "WordPairs",
        "GrammarForm",
        "DialogueCompletion",
    }
)

TEMPLATE_COUNT_HEADERS = ["Template", "Count in level"]

QUESTION_SUMMARY_HEADERS = ["#", "Line 1", "Line 2", "Answer", "Distractors"]

WORD_FREQ_HEADERS = ["word", "count"]

# Per-question keys omitted from HTML word-frequency (metadata / assets).
_QUESTION_ITEM_WORD_FREQ_SKIP_KEYS = frozenset(
    {"template", "audio_file", "audio_file1", "audio_file2"}
)

# questionData keys omitted from HTML word-frequency (wrong options).
_QD_WORD_FREQ_SKIP_KEYS = frozenset({"distractors", "wrongAnswers"})

# Same token pattern as tools/update_final_word_counts_from_levels.py
_WORD_FREQ_TOKEN_RE = re.compile(r"[a-z0-9]+(?:[-'][a-z0-9]+)*", re.IGNORECASE)

# Ignored when checking partial phrase overlap (e.g. "to ask a question" → ask, question).
_PHRASE_STOP_WORDS = frozenset(
    {
        "to",
        "a",
        "an",
        "the",
        "and",
        "or",
        "of",
        "in",
        "on",
        "at",
        "for",
        "with",
        "your",
        "my",
        "his",
        "her",
        "our",
        "their",
        "its",
        "this",
        "that",
        "some",
    }
)


_BLANK_CORE_RE = re.compile(r"^_{2,}$")

# Strip before checking blank core so `_____.` / `____?` / `_____!` count as blanks.
_LEADING_CLOZE_PUNCT = frozenset("\"'([{«")
_TRAILING_CLOZE_PUNCT = frozenset(".,!?;:'\")]}»\u2026")


def _strip_cloze_blank_affixes(token: str) -> str:
    t = token.strip()
    while t and t[0] in _LEADING_CLOZE_PUNCT:
        t = t[1:]
    while t and t[-1] in _TRAILING_CLOZE_PUNCT:
        t = t[:-1]
    return t


def _is_cloze_blank_token(token: str) -> bool:
    return bool(_BLANK_CORE_RE.match(_strip_cloze_blank_affixes(token)))


def _count_blanks(sentence: str) -> int:
    return sum(1 for t in sentence.split(" ") if _is_cloze_blank_token(t))


def collect_word_frequency_rows(questions_json_root: dict) -> list[list[str]]:
    """
    String values under questions.json, tokenized (lowercased), except each
    question’s `template`, `audio_file` / `audio_file1` / `audio_file2`, and in
    questionData: translations (WordPairs only), distractors, wrongAnswers.
    Rows sorted by count descending, then word.
    """
    counts: Counter[str] = Counter()

    def feed_string(s: str) -> None:
        s = (s or "").strip()
        if not s:
            return
        for m in _WORD_FREQ_TOKEN_RE.finditer(s):
            counts[m.group(0).lower()] += 1

    def walk(obj) -> None:
        if isinstance(obj, str):
            feed_string(obj)
        elif isinstance(obj, dict):
            for v in obj.values():
                walk(v)
        elif isinstance(obj, list):
            for x in obj:
                walk(x)

    def walk_question_data(qd: dict, template: str) -> None:
        for k, v in qd.items():
            if k in _QD_WORD_FREQ_SKIP_KEYS:
                continue
            if template == "WordPairs" and k == "translations":
                continue
            walk(v)

    root = questions_json_root
    if not isinstance(root, dict):
        return []

    for top_k, top_v in root.items():
        if top_k == "levelQuestions" and isinstance(top_v, list):
            for item in top_v:
                if not isinstance(item, dict):
                    walk(item)
                    continue
                tpl = item.get("template")
                tpl_s = tpl if isinstance(tpl, str) else ""
                for ik, iv in item.items():
                    if ik in _QUESTION_ITEM_WORD_FREQ_SKIP_KEYS:
                        continue
                    if ik == "questionData" and isinstance(iv, dict):
                        walk_question_data(iv, tpl_s)
                    else:
                        walk(iv)
        else:
            walk(top_v)

    order = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return [[w, str(n)] for w, n in order]


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def normalize_phrase(text: str) -> str:
    return " ".join((text or "").strip().split()).lower()


def build_word_type_index(csv_dir: Path) -> dict[str, str]:
    """Map normalized headword (and bare stem after ``to ``) -> coarse type from final-word CSVs."""
    index: dict[str, str] = {}
    if not csv_dir.is_dir():
        return index
    for filename, word_type in _FINAL_CSV_WORD_TYPES.items():
        path = csv_dir / filename
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        if text.startswith("\ufeff"):
            text = text.lstrip("\ufeff")
        reader = csv.DictReader(text.splitlines())
        if not reader.fieldnames:
            continue
        lower_map = {f.lower(): f for f in reader.fieldnames}
        wkey = lower_map.get("word") or lower_map.get("adverb")
        if not wkey:
            continue
        for row in reader:
            if not row:
                continue
            raw = (row.get(wkey) or "").strip()
            if not raw:
                continue
            phrase = normalize_phrase(raw)
            if phrase and phrase not in index:
                index[phrase] = word_type
            if phrase.startswith("to "):
                bare = phrase[3:].strip()
                if bare and bare not in index:
                    index[bare] = word_type
    return index


def classify_prior_word(english_word: str, type_index: dict[str, str]) -> str:
    """Assign verb / adjective / adverb / … using final-word CSVs, with simple fallbacks."""
    phrase = normalize_phrase(english_word)
    if not phrase:
        return "other"
    if phrase in type_index:
        return type_index[phrase]
    if phrase.startswith("to "):
        bare = phrase[3:].strip()
        if bare in type_index:
            return type_index[bare]
        return "verb"
    # Multi-word phrases (e.g. "My name is", "thank you") — avoid token guessing.
    if " " in phrase:
        return "other"
    if phrase in type_index:
        return type_index[phrase]
    tokens = [t for t in _WORD_FREQ_TOKEN_RE.findall(phrase) if t not in _PHRASE_STOP_WORDS]
    for tok in tokens:
        if tok in type_index:
            return type_index[tok]
    return "other"


def collect_prior_vocabulary_entries(
    target_level: str,
    *,
    flow_path: Path,
    levels_root: Path,
) -> tuple[list[tuple[str, str, str]], list[str], int]:
    """
    Return (deduped entries, prior flow icon names, prior level folder count).
    Each entry is (word, level_label, source).
    """
    if load_flow_order is None or resolve_prior_level_dirs is None:
        raise RuntimeError("gather_prior_level_words import failed")
    flow_order = load_flow_order(flow_path)
    if target_level not in flow_order:
        raise ValueError(
            f"level {target_level!r} not in {flow_path.name} "
            f"({len(flow_order)} entries)"
        )
    target_idx = flow_order.index(target_level)
    prior_names = flow_order[:target_idx]

    prior_dirs, missing = resolve_prior_level_dirs(
        prior_names,
        levels_root=levels_root,
        flow_path=flow_path,
    )

    all_entries: list[tuple[str, str, str]] = []
    for _name, d in prior_dirs:
        all_entries.extend(collect_level_vocabulary(d, levels_root))
    return dedupe_entries(all_entries), missing, len(prior_dirs)


def build_prior_words_markdown(
    target_level: str,
    entries: list[tuple[str, str, str]],
    *,
    prior_level_count: int,
    missing_flow_levels: list[str],
    type_index: dict[str, str],
) -> str:
    grouped: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    for word, level, source in entries:
        wtype = classify_prior_word(word, type_index)
        grouped[wtype].append((word, level, source))

    lines = [
        f"# {target_level} — prior vocabulary (by type)",
        "",
        f"Words and phrases from **translations.json** and **WordPairs** in the "
        f"**{prior_level_count}** flow level(s) before `{target_level}`.",
        "",
        f"**Total distinct entries:** {len(entries)}",
        "",
    ]
    if missing_flow_levels:
        lines.append(
            f"*Warning: {len(missing_flow_levels)} flow level(s) not found on disk: "
            + ", ".join(missing_flow_levels)
            + "*"
        )
        lines.append("")

    for wtype in _PRIOR_TYPE_SECTION_ORDER:
        items = grouped.get(wtype, [])
        title = wtype.capitalize() + ("s" if wtype != "other" else "")
        lines.append(f"## {title} ({len(items)})")
        lines.append("")
        if not items:
            lines.append("_None_")
        else:
            for word, level, source in items:
                lines.append(f"- {word} — `{level}` ({source})")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def write_prior_words_by_type(
    target_level: str,
    output_dir: Path,
    *,
    flow_path: Path,
    levels_root: Path,
    csv_dir: Path,
    dry_run: bool = False,
) -> Path | None:
    """Write ``prior-words-by-type.md`` (fixed name, overwritten each run); return path or None if skipped."""
    if collect_prior_vocabulary_entries is None:
        print(
            "Skip prior-words report: could not import gather_prior_level_words",
            file=sys.stderr,
        )
        return None
    try:
        entries, missing, prior_count = collect_prior_vocabulary_entries(
            target_level,
            flow_path=flow_path,
            levels_root=levels_root,
        )
    except ValueError as e:
        print(f"Skip prior-words report: {e}", file=sys.stderr)
        return None

    type_index = build_word_type_index(csv_dir)
    body = build_prior_words_markdown(
        target_level,
        entries,
        prior_level_count=prior_count,
        missing_flow_levels=missing,
        type_index=type_index,
    )
    out_path = output_dir / "prior-words-by-type.md"
    if dry_run:
        print(f"[dry-run] Would write {out_path} ({len(entries)} prior words)")
        return out_path
    out_path.write_text(body, encoding="utf-8")
    print(f"Wrote {out_path} ({len(entries)} prior words in {prior_count} level(s))")
    return out_path


def _nonempty_str(value) -> str:
    if value is None:
        return ""
    return str(value).strip()


def _english_line_field(raw) -> str:
    """Match LevelConfig._englishLineField: string or {"en": ...}."""
    if raw is None:
        return ""
    if isinstance(raw, str):
        return raw.strip()
    if isinstance(raw, dict):
        en = raw.get("en")
        return (str(en).strip() if en is not None else "") or ""
    return ""


def _string_list(value) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(x) for x in value]


def _words_from_array_or_sentence_typed(value) -> list[str]:
    """Same splitting as summarize helpers; empty if wrong type."""
    if isinstance(value, list):
        return [str(x) for x in value]
    if isinstance(value, str):
        trimmed = value.strip()
        if not trimmed:
            return []
        return re.split(r"\s+", trimmed)
    return []


def _grammar_sentence_str(raw) -> str:
    if isinstance(raw, str):
        return raw.strip()
    if isinstance(raw, dict):
        en = raw.get("en")
        return str(en).strip() if en is not None else ""
    return ""


def _wrong_answers_image_tpl(data: dict) -> list[str]:
    raw = data.get("wrongAnswers")
    if raw is None:
        raw = data.get("distractors")
    if not isinstance(raw, list):
        return []
    return [str(x) for x in raw]


def validate_question_shape(index: int, item: dict) -> list[str]:
    """
    Return human-readable errors for this question (1-based index).
    Empty list means OK.
    """
    errs: list[str] = []
    prefix = f"Question {index}"

    for bad_key in ("english_to_translate", "local_translation"):
        if bad_key in item:
            errs.append(
                f"{prefix}: `{bad_key}` must be inside `questionData`, not at question root"
            )

    qd = item.get("questionData")
    if not isinstance(qd, dict):
        errs.append(f"{prefix}: `questionData` must be a JSON object")
        return errs

    template = _nonempty_str(item.get("template"))
    if not template:
        errs.append(f"{prefix}: missing or empty `template`")
        return errs

    if template not in _KNOWN_TEMPLATES:
        errs.append(
            f"{prefix}: unknown template `{template}` (not in level_config.dart)"
        )
        return errs

    a1 = _nonempty_str(item.get("audio_file1"))
    a2 = _nonempty_str(item.get("audio_file2"))
    if bool(a1) != bool(a2):
        errs.append(
            f"{prefix}: `audio_file1` and `audio_file2` must both be non-empty "
            "or both omitted (paired split-audio fields)"
        )

    et = qd.get("english_to_translate")
    if et is not None and not isinstance(et, list):
        errs.append(f"{prefix}: `questionData.english_to_translate` must be an array")
    lt = qd.get("local_translation")
    if lt is not None and not isinstance(lt, dict):
        errs.append(
            f"{prefix}: `questionData.local_translation` must be a locale map (object)"
        )

    if template == "imageQuizTemplate-1":
        name = _nonempty_str(qd.get("imageName"))
        if not name:
            errs.append(
                f"{prefix} ({template}): `questionData.imageName` is required and must be non-empty"
            )
        wrong = _wrong_answers_image_tpl(qd)
        if len(wrong) != 3:
            errs.append(
                f"{prefix} ({template}): need exactly 3 `wrongAnswers` or `distractors` "
                f"(got {len(wrong)})"
            )

    elif template == "imageQuizTemplate-2":
        name = _nonempty_str(qd.get("imageName"))
        if not name:
            errs.append(
                f"{prefix} (imageQuizTemplate-2): `questionData.imageName` is required and must be non-empty"
            )
        raw_wrong = qd.get("wrongAnswers")
        if not isinstance(raw_wrong, list):
            wrong = []
        else:
            wrong = [str(x) for x in raw_wrong]
        if len(wrong) != 3:
            errs.append(
                f"{prefix} (imageQuizTemplate-2): need exactly 3 `wrongAnswers` "
                f"(got {len(wrong)}; do not use `distractors` here)"
            )

    elif template == "ConvoTemplate-1":
        for field in ("character1", "character2"):
            if not _nonempty_str(qd.get(field)):
                errs.append(
                    f"{prefix} (ConvoTemplate-1): `questionData.{field}` is required and must be non-empty"
                )
        if not _english_line_field(qd.get("line1")):
            errs.append(
                f"{prefix} (ConvoTemplate-1): `questionData.line1` is required (string or {{\"en\": ...}})"
            )
        if not _english_line_field(qd.get("line2")):
            errs.append(
                f"{prefix} (ConvoTemplate-1): `questionData.line2` is required (string or {{\"en\": ...}})"
            )
        if not _nonempty_str(qd.get("answer")):
            errs.append(
                f"{prefix} (ConvoTemplate-1): `questionData.answer` is required and must be non-empty"
            )
        dist = _string_list(qd.get("distractors"))
        if len(dist) != 3:
            errs.append(
                f"{prefix} (ConvoTemplate-1): need exactly 3 `distractors` (got {len(dist)})"
            )

    elif template == "DialogueCompletion":
        for field in ("character1", "character2"):
            if not _nonempty_str(qd.get(field)):
                errs.append(
                    f"{prefix} (DialogueCompletion): `questionData.{field}` is required and must be non-empty"
                )
        if not _english_line_field(qd.get("line1")):
            errs.append(
                f"{prefix} (DialogueCompletion): `questionData.line1` is required"
            )
        if not _nonempty_str(qd.get("answer")):
            errs.append(
                f"{prefix} (DialogueCompletion): `questionData.answer` is required and must be non-empty"
            )
        dist = _string_list(qd.get("distractors"))
        if len(dist) != 3:
            errs.append(
                f"{prefix} (DialogueCompletion): need exactly 3 `distractors` (got {len(dist)})"
            )

    elif template == "AppearDisappear":
        words = _words_from_array_or_sentence_typed(qd.get("words"))
        if not words:
            errs.append(
                f"{prefix} (AppearDisappear): `questionData.words` must be a non-empty string or array"
            )

    elif template == "ClozeSequence":
        raw_sent = qd.get("sentence")
        if not isinstance(raw_sent, str):
            errs.append(
                f"{prefix} (ClozeSequence): `questionData.sentence` must be a plain English string "
                "(not a locale map)"
            )
        else:
            sentence = raw_sent.strip()
            if not sentence:
                errs.append(
                    f"{prefix} (ClozeSequence): `questionData.sentence` must be non-empty"
                )
            else:
                raw_ans = qd.get("answer")
                if raw_ans is None:
                    raw_ans = qd.get("answers")
                if isinstance(raw_ans, list):
                    answers = [str(x) for x in raw_ans]
                elif isinstance(raw_ans, str) and raw_ans.strip():
                    answers = [raw_ans.strip()]
                else:
                    answers = []
                blank_count = _count_blanks(sentence)
                if blank_count == 0:
                    errs.append(
                        f"{prefix} (ClozeSequence): sentence must contain at least one blank token "
                        "like `_____` or `_____.` / `____?` (space-delimited; optional .!? after underscores)"
                    )
                elif blank_count != len(answers):
                    errs.append(
                        f"{prefix} (ClozeSequence): {len(answers)} answer(s) but {blank_count} blank(s) in sentence"
                    )
        dist = _string_list(qd.get("distractors"))
        if not dist:
            errs.append(
                f"{prefix} (ClozeSequence): `questionData.distractors` must be a non-empty array"
            )

    elif template == "SentenceBuilder":
        tokens = _words_from_array_or_sentence_typed(qd.get("correct_order"))
        if len(tokens) < 2:
            errs.append(
                f"{prefix} (SentenceBuilder): `correct_order` must have at least 2 tokens "
                f"(got {len(tokens)})"
            )

    elif template == "WordPairs":
        ew = _string_list(qd.get("english_words"))
        tr_list = qd.get("translations")
        if not isinstance(tr_list, list):
            tr_list = []
        if len(ew) != len(tr_list):
            errs.append(
                f"{prefix} (WordPairs): `english_words` length ({len(ew)}) must match "
                f"`translations` length ({len(tr_list)})"
            )
        for i, row in enumerate(tr_list):
            if not isinstance(row, dict) or not row:
                errs.append(
                    f"{prefix} (WordPairs): `translations[{i}]` must be a non-empty locale map"
                )
        n = len(ew)
        if n < 3 or n > 6:
            errs.append(
                f"{prefix} (WordPairs): expect 3–6 pairs, got {n}"
            )

    elif template == "GrammarForm":
        sentence = _grammar_sentence_str(qd.get("sentence"))
        if not sentence:
            errs.append(
                f"{prefix} (GrammarForm): `questionData.sentence` is required (string or {{\"en\": ...}})"
            )
        elif "___" not in sentence and "_____" not in sentence:
            errs.append(
                f"{prefix} (GrammarForm): sentence must contain a blank (`___` or `_____`)"
            )
        if not _nonempty_str(qd.get("answer")):
            errs.append(
                f"{prefix} (GrammarForm): `questionData.answer` is required and must be non-empty"
            )
        dist = _string_list(qd.get("distractors"))
        if len(dist) != 3:
            errs.append(
                f"{prefix} (GrammarForm): need exactly 3 `distractors` (got {len(dist)})"
            )

    return errs


def validate_level_questions(questions: list) -> list[str]:
    """Flat list of error lines; empty => all questions valid."""
    out: list[str] = []
    for i, item in enumerate(questions, start=1):
        if not isinstance(item, dict):
            out.append(f"Question {i}: must be a JSON object")
            continue
        out.extend(validate_question_shape(i, item))
    return out


def escape_md_cell(value: str) -> str:
    s = str(value or "")
    s = s.replace("\r", " ").replace("\n", " ")
    return s.replace("|", r"\|")


def words_from_array_or_sentence(value) -> list[str]:
    if isinstance(value, list):
        return [str(x) for x in value]
    if isinstance(value, str):
        trimmed = value.strip()
        if not trimmed:
            return []
        return re.split(r"\s+", trimmed)
    return []


def distractors_cell(template: str, question_data: dict) -> str:
    """Join distractors or wrongAnswers for summary table; empty if none."""
    if template in ("imageQuizTemplate-1", "imageQuizTemplate-2"):
        items = _wrong_answers_image_tpl(question_data)
    else:
        items = _string_list(question_data.get("distractors"))
    return "; ".join(x.strip() for x in items if str(x).strip())


def summarize_row(template: str, question_data: dict) -> tuple[str, str, str]:
    if template == "imageQuizTemplate-1":
        image_name = (question_data.get("imageName") or "").strip()
        answer = (question_data.get("answer") or image_name or "").strip()
        return (f"image: {image_name}" if image_name else "(no image)", "", answer)

    if template == "imageQuizTemplate-2":
        image_name = (question_data.get("imageName") or "").strip()
        answer = (question_data.get("answer") or image_name or "").strip()
        return (f"image: {image_name}" if image_name else "(no image)", "", answer)

    if template == "ConvoTemplate-1":
        return (
            _english_line_field(question_data.get("line1")),
            _english_line_field(question_data.get("line2")),
            _nonempty_str(question_data.get("answer")),
        )

    if template == "DialogueCompletion":
        return (
            _english_line_field(question_data.get("line1")),
            "",
            _nonempty_str(question_data.get("answer")),
        )

    if template == "AppearDisappear":
        words = words_from_array_or_sentence(question_data.get("words"))
        line1 = " ".join(words) if words else str(question_data.get("words", ""))
        return (line1, "", "-")

    if template == "ClozeSequence":
        sentence = str(question_data.get("sentence", ""))
        raw_answer = question_data.get("answer")
        if raw_answer is None:
            raw_answer = question_data.get("answers")
        if isinstance(raw_answer, list):
            answer = ", ".join(str(x) for x in raw_answer)
        else:
            answer = str(raw_answer or "")
        return (sentence, "", answer)

    if template == "SentenceBuilder":
        correct_order = question_data.get("correct_order")
        if isinstance(correct_order, list):
            sentence = " ".join(str(x) for x in correct_order)
        else:
            sentence = str(correct_order or "").strip()
        return (sentence, "", sentence)

    if template == "WordPairs":
        words = question_data.get("english_words")
        if isinstance(words, list):
            line1 = "; ".join(str(x) for x in words)
        else:
            line1 = str(words or "")
        return (line1, "word pairs", "match all pairs")

    if template == "GrammarForm":
        sentence = _grammar_sentence_str(question_data.get("sentence"))
        raw_answer = question_data.get("answer")
        if isinstance(raw_answer, list):
            answer = ", ".join(str(x) for x in raw_answer)
        else:
            answer = str(raw_answer or "")
        return (sentence, "", answer)

    return (f"(unsupported template {template})", "", "")


def _cloze_answer_strings(question_data: dict) -> list[str]:
    raw = question_data.get("answer")
    if raw is None:
        raw = question_data.get("answers")
    if isinstance(raw, list):
        return [str(x).strip() for x in raw if str(x).strip()]
    if isinstance(raw, str) and raw.strip():
        return [raw.strip()]
    return []


def _answer_strings_for_template(template: str, question_data: dict) -> list[str]:
    """Answer tokens/phrases only (never distractors or wrongAnswers)."""
    if template in ("ConvoTemplate-1", "DialogueCompletion", "GrammarForm"):
        a = _nonempty_str(question_data.get("answer"))
        return [a] if a else []
    if template == "ClozeSequence":
        return _cloze_answer_strings(question_data)
    if template == "WordPairs":
        return [str(x).strip() for x in _string_list(question_data.get("english_words")) if str(x).strip()]
    if template in ("imageQuizTemplate-1", "imageQuizTemplate-2"):
        a = _nonempty_str(question_data.get("answer"))
        if a:
            return [a]
        name = _nonempty_str(question_data.get("imageName"))
        return [name] if name else []
    return []


def _question_text_parts(template: str, question_data: dict) -> list[str]:
    """Prompt / sentence text only (no distractors, wrongAnswers, or WordPairs locale maps)."""
    parts: list[str] = []

    if template in ("ConvoTemplate-1", "DialogueCompletion"):
        for key in ("line1", "line2"):
            s = _english_line_field(question_data.get(key))
            if s:
                parts.append(s)
    elif template == "AppearDisappear":
        words = question_data.get("words")
        if isinstance(words, str) and words.strip():
            parts.append(words.strip())
        elif isinstance(words, list):
            parts.extend(str(x).strip() for x in words if str(x).strip())
    elif template == "ClozeSequence":
        s = question_data.get("sentence")
        if isinstance(s, str) and s.strip():
            parts.append(s.strip())
    elif template == "SentenceBuilder":
        parts.extend(_words_from_array_or_sentence_typed(question_data.get("correct_order")))
    elif template == "GrammarForm":
        s = _grammar_sentence_str(question_data.get("sentence"))
        if s:
            parts.append(s)
    elif template == "WordPairs":
        parts.extend(_string_list(question_data.get("english_words")))
    elif template in ("imageQuizTemplate-1", "imageQuizTemplate-2"):
        name = _nonempty_str(question_data.get("imageName"))
        if name:
            parts.append(name)

    return parts


def load_translation_english_words(translations_path: Path) -> list[str]:
    """Ordered english_word list from translations.json (file order)."""
    if not translations_path.is_file():
        return []
    try:
        data = json.loads(translations_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    lst = data.get("translations_list")
    if not isinstance(lst, list):
        return []
    out: list[str] = []
    for e in lst:
        if not isinstance(e, dict):
            continue
        ew = e.get("english_word")
        if isinstance(ew, str) and ew.strip():
            out.append(ew.strip())
    return out


def _content_tokens(english_word: str) -> list[str]:
    """Significant tokens from a translation headword (drops to/a/the etc.)."""
    tokens = _WORD_FREQ_TOKEN_RE.findall(english_word.lower())
    return [t for t in tokens if t not in _PHRASE_STOP_WORDS]


def _token_in_haystack(token: str, haystack: str) -> bool:
    """Word-boundary match, including simple inflections (ask ↔ asks)."""
    if not token:
        return False
    if re.search(r"(?<![a-z0-9-])" + re.escape(token) + r"(?![a-z0-9-])", haystack):
        return True
    for suffix in ("s", "es", "ed", "ing"):
        inflected = token + suffix
        if re.search(
            r"(?<![a-z0-9-])" + re.escape(inflected) + r"(?![a-z0-9-])", haystack
        ):
            return True
    return False


def _partial_phrase_match(english_word: str, haystack: str) -> bool:
    """
    True when all content words of a multi-word headword appear in haystack.
    E.g. "to ask a question" matches "Teacher asks an easy question."
    """
    tokens = _content_tokens(english_word)
    if len(tokens) < 2:
        return False
    return all(_token_in_haystack(t, haystack) for t in tokens)


def _translation_matches_question(
    english_word: str, haystack: str, answer_strings: list[str]
) -> bool:
    """True if english_word appears in question text or answer(s) (full or partial)."""
    ew = english_word.lower().strip()
    if not ew:
        return False

    if ew in haystack:
        return True

    answers_lower = [a.lower() for a in answer_strings if a.strip()]
    if ew in answers_lower:
        return True

    bare = ew[3:].strip() if ew.startswith("to ") else ""
    if bare:
        if _token_in_haystack(bare, haystack):
            return True
        if bare in answers_lower:
            return True

    # Short headwords in text (e.g. translation "today" in "... learn today?")
    if " " not in ew and len(ew) >= 2:
        if _token_in_haystack(ew, haystack):
            return True

    # Partial phrase (e.g. "to ask a question" in "Teacher asks an easy question.")
    if _partial_phrase_match(ew, haystack):
        return True

    return False


def _wordpairs_translated_english_words(question_data: dict) -> str:
    """All english_words with a paired non-empty entry in questionData.translations."""
    words = _string_list(question_data.get("english_words"))
    tr_list = question_data.get("translations")
    if not isinstance(tr_list, list):
        return ""
    out: list[str] = []
    for i, w in enumerate(words):
        w = w.strip()
        if not w:
            continue
        if i < len(tr_list) and isinstance(tr_list[i], dict) and tr_list[i]:
            out.append(w)
    return "; ".join(out)


def english_translate_cell(
    template: str,
    question_data: dict,
    translation_words: list[str],
) -> str:
    """
    english_word entries from translations.json that appear in this question's
    prompt/sentence text or answer(s). WordPairs: all english_words with embedded
    translations. Ignores distractors and wrongAnswers.
    Falls back to questionData.english_to_translate when no translations.json words.
    """
    if template == "WordPairs":
        return _wordpairs_translated_english_words(question_data)

    if translation_words:
        text_parts = _question_text_parts(template, question_data)
        answer_strings = _answer_strings_for_template(template, question_data)
        haystack = " ".join(text_parts + answer_strings).lower()
        matched = [
            ew
            for ew in translation_words
            if _translation_matches_question(ew, haystack, answer_strings)
        ]
        return "; ".join(matched)

    raw = question_data.get("english_to_translate")
    if not isinstance(raw, list) or not raw:
        return ""
    parts = [str(x).strip() for x in raw if str(x).strip()]
    return "; ".join(parts)


def audio_files_cell(item: dict) -> str:
    """Top-level audio basenames (sibling to template), only keys that exist and are non-empty."""
    segments: list[str] = []
    for key in ("audio_file", "audio_file1", "audio_file2"):
        val = item.get(key)
        if val is None:
            continue
        s = str(val).strip()
        if not s:
            continue
        segments.append(f"{key}: {s}")
    return " · ".join(segments)


def collect_template_count_rows(questions: list) -> list[list[str]]:
    """
    One row per template in _KNOWN_TEMPLATES (sorted), value = occurrences of that
    exact template string in levelQuestions (after validation, only known templates appear).
    """
    counts: dict[str, int] = {t: 0 for t in _KNOWN_TEMPLATES}
    for item in questions:
        if not isinstance(item, dict):
            continue
        t = str(item.get("template", "")).strip()
        if t in counts:
            counts[t] += 1
    order = sorted(counts.keys(), key=str.lower)
    return [[tpl, str(counts[tpl])] for tpl in order]


def collect_question_summary_rows(questions: list) -> list[list[str]]:
    """Compact rows for HTML summary: #, line1, line2, answer, distractors."""
    rows: list[list[str]] = []
    for index, item in enumerate(questions, start=1):
        if not isinstance(item, dict):
            rows.append([str(index), "(invalid)", "", "", ""])
            continue
        template = str(item.get("template", ""))
        question_data = item.get("questionData")
        if not isinstance(question_data, dict):
            rows.append([str(index), "(missing questionData)", "", "", ""])
            continue
        line1, line2, answer = summarize_row(template, question_data)
        dist = distractors_cell(template, question_data)
        rows.append([str(index), line1, line2, answer, dist])
    return rows


def collect_rows(
    questions: list, translation_words: list[str] | None = None
) -> list[list[str]]:
    """One data row = seven plain strings (no format-specific escaping)."""
    tw = translation_words or []
    rows: list[list[str]] = []
    for index, item in enumerate(questions, start=1):
        if not isinstance(item, dict):
            rows.append(
                [str(index), "(invalid)", "(not an object)", "", "", "", ""]
            )
            continue
        template = str(item.get("template", ""))
        question_data = item.get("questionData")
        if not isinstance(question_data, dict):
            rows.append(
                [
                    str(index),
                    template,
                    "(missing questionData)",
                    "",
                    "",
                    "",
                    "",
                ]
            )
            continue

        line1, line2, answer = summarize_row(template, question_data)
        en_tr = english_translate_cell(template, question_data, tw)
        audio = audio_files_cell(item)
        rows.append(
            [
                str(index),
                template,
                line1,
                line2,
                answer,
                en_tr,
                audio,
            ]
        )
    return rows


def collect_translation_rows(translations_path: Path) -> tuple[list[str], list[list[str]]] | None:
    """
    Parse translations.json -> (headers, rows). Returns None if file missing,
    invalid, or translations_list empty or has no usable entries.
    Headers: #, English word, <sorted locale codes>.
    """
    if not translations_path.is_file():
        return None
    try:
        data = json.loads(translations_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    lst = data.get("translations_list")
    if not isinstance(lst, list) or not lst:
        return None

    all_locales: set[str] = set()
    raw_entries: list[tuple[str, dict[str, str]]] = []
    for e in lst:
        if not isinstance(e, dict):
            continue
        ew = e.get("english_word")
        if not isinstance(ew, str):
            continue
        tr_raw = e.get("translations")
        clean: dict[str, str] = {}
        if isinstance(tr_raw, dict):
            for k, v in tr_raw.items():
                if v is None:
                    continue
                clean[str(k)] = str(v)
        for k in clean:
            all_locales.add(k)
        raw_entries.append((ew, clean))

    if not raw_entries:
        return None

    locales = sorted(all_locales)
    headers = ["#", "English word"] + locales
    rows: list[list[str]] = []
    for idx, (ew, clean) in enumerate(raw_entries, start=1):
        row = [str(idx), ew] + [clean.get(loc, "") for loc in locales]
        rows.append(row)
    return (headers, rows)


def build_markdown(
    level_name: str,
    template_count_rows: list[list[str]],
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    lines = [
        f"# {level_name} questions",
        "",
        f"## {level_name} — template counts",
        "",
        "| " + " | ".join(TEMPLATE_COUNT_HEADERS) + " |",
        "|" + "|".join(["---"] * len(TEMPLATE_COUNT_HEADERS)) + "|",
    ]
    for r in template_count_rows:
        esc = [escape_md_cell(c) for c in r]
        lines.append("| " + " | ".join(esc) + " |")
    lines.extend(
        [
            "",
            f"## {level_name} — questions",
            "",
            "| " + " | ".join(TABLE_HEADERS) + " |",
            "|" + "|".join(["---:"] + ["---"] * (len(TABLE_HEADERS) - 1)) + "|",
        ]
    )
    for r in rows:
        esc = [escape_md_cell(c) for c in r]
        lines.append("| " + " | ".join(esc) + " |")
    lines.append("")

    if trans:
        th, trows = trans
        lines.extend(
            [
                f"## {level_name} — translations",
                "",
                "| " + " | ".join(th) + " |",
                "|" + "|".join(["---:"] + ["---"] * (len(th) - 1)) + "|",
            ]
        )
        for r in trows:
            esc = [escape_md_cell(c) for c in r]
            lines.append("| " + " | ".join(esc) + " |")
        lines.append("")

    return "\n".join(lines)


def tsv_cell(value: str) -> str:
    return str(value or "").replace("\t", " ").replace("\r", " ").replace("\n", " ")


def build_tsv(
    template_count_rows: list[list[str]],
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    out_lines = [
        "\t".join(tsv_cell(h) for h in TEMPLATE_COUNT_HEADERS),
    ]
    for r in template_count_rows:
        out_lines.append("\t".join(tsv_cell(c) for c in r))
    out_lines.append("")
    out_lines.append("\t".join(tsv_cell(h) for h in TABLE_HEADERS))
    for r in rows:
        out_lines.append("\t".join(tsv_cell(c) for c in r))
    if trans:
        th, trows = trans
        out_lines.append("")
        out_lines.append("\t".join(tsv_cell(h) for h in th))
        for r in trows:
            out_lines.append("\t".join(tsv_cell(c) for c in r))
    return "\n".join(out_lines) + "\n"


def build_csv(
    template_count_rows: list[list[str]],
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    import io

    buf = io.StringIO(newline="")
    w = csv.writer(buf)
    w.writerow(TEMPLATE_COUNT_HEADERS)
    for r in template_count_rows:
        w.writerow(r)
    w.writerow([])
    w.writerow(TABLE_HEADERS)
    for r in rows:
        w.writerow(r)
    if trans:
        th, trows = trans
        w.writerow([])
        w.writerow(th)
        for r in trows:
            w.writerow(r)
    return buf.getvalue()


def _parse_translate_cell(cell: str) -> list[str]:
    """Split English (translate) cell on ';' into trimmed phrases."""
    if not (cell or "").strip():
        return []
    return [p.strip() for p in str(cell).split(";") if p.strip()]


def repeated_translate_words(rows: list[list[str]]) -> frozenset[str]:
    """
    Lowercase headwords that appear more than once across the English (translate)
    column (including duplicates within a single cell).
    """
    counts: Counter[str] = Counter()
    for row in rows:
        if len(row) <= _ENGLISH_TRANSLATE_COL:
            continue
        for phrase in _parse_translate_cell(row[_ENGLISH_TRANSLATE_COL]):
            counts[phrase.lower()] += 1
    return frozenset(k for k, v in counts.items() if v > 1)


def _html_translate_cell(cell: str, repeated_lower: frozenset[str]) -> str:
    parts = _parse_translate_cell(cell)
    if not parts:
        return ""
    rendered: list[str] = []
    for phrase in parts:
        esc = html.escape(phrase)
        if phrase.lower() in repeated_lower:
            rendered.append(f'<span class="repeat-word">{esc}</span>')
        else:
            rendered.append(esc)
    return "; ".join(rendered)


def _html_table(
    headers: list[str],
    data_rows: list[list[str]],
    *,
    highlight_translate_repeats: frozenset[str] | None = None,
) -> str:
    thead = "<thead><tr>" + "".join(f"<th>{html.escape(h)}</th>" for h in headers) + "</tr></thead>"
    body_rows = []
    for r in data_rows:
        cells: list[str] = []
        for col_i, c in enumerate(r):
            if (
                highlight_translate_repeats is not None
                and col_i == _ENGLISH_TRANSLATE_COL
            ):
                cells.append(f"<td>{_html_translate_cell(c, highlight_translate_repeats)}</td>")
            else:
                cells.append(f"<td>{html.escape(c)}</td>")
        body_rows.append(f"<tr>{''.join(cells)}</tr>")
    tbody = "<tbody>" + "".join(body_rows) + "</tbody>"
    return f"<table>\n{thead}\n{tbody}\n</table>"


def build_html(
    level_name: str,
    template_count_rows: list[list[str]],
    rows: list[list[str]],
    question_summary_rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
    word_freq_rows: list[list[str]],
) -> str:
    style = """
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; margin: 16px; background: #f5f5f5; }
    h1 { font-size: 1.25rem; margin-bottom: 12px; }
    h2 { font-size: 1.1rem; margin-top: 24px; margin-bottom: 8px; }
    .wrap { overflow-x: auto; background: #fff; padding: 12px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,.08); margin-bottom: 16px; }
    table { border-collapse: collapse; width: 100%; font-size: 13px; table-layout: fixed; }
    th, td { border: 1px solid #c8c8c8; padding: 8px 10px; vertical-align: top; text-align: left; word-wrap: break-word; }
    th { background: #e8e8e8; font-weight: 600; white-space: nowrap; }
    tr:nth-child(even) td { background: #fafafa; }
    .repeat-word { color: #c62828; font-weight: 600; }
    .wrap.template-counts { max-width: 28rem; }
    .wrap.word-frequency { max-width: 40rem; }
    """
    tpl_table = _html_table(TEMPLATE_COUNT_HEADERS, template_count_rows)
    translate_repeats = repeated_translate_words(rows)
    q_table = _html_table(
        TABLE_HEADERS, rows, highlight_translate_repeats=translate_repeats
    )
    trans_block = ""
    if trans:
        th, trows = trans
        trans_table = _html_table(th, trows)
        trans_block = f"""
  <h2>{html.escape(level_name)} — translations</h2>
  <div class="wrap">
    {trans_table}
  </div>
"""
    summary_table = _html_table(QUESTION_SUMMARY_HEADERS, question_summary_rows)
    question_summary_block = f"""
  <h2>Question summary</h2>
  <div class="wrap">
    {summary_table}
  </div>
"""
    template_counts_block = f"""
  <h2>Template counts</h2>
  <div class="wrap template-counts">
    {tpl_table}
  </div>
"""
    word_freq_table = _html_table(WORD_FREQ_HEADERS, word_freq_rows)
    word_freq_block = f"""
  <h2>Word frequency (questions.json; excludes template, audio_file*, WordPairs translations, distractors, wrongAnswers)</h2>
  <div class="wrap word-frequency">
    {word_freq_table}
  </div>
"""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(level_name)} — level tables</title>
  <style>{style}</style>
</head>
<body>
  <h1>{html.escape(level_name)} — questions</h1>
  <h2>Questions</h2>
  <div class="wrap">
    {q_table}
  </div>
{trans_block}{question_summary_block}{template_counts_block}{word_freq_block}
</body>
</html>
"""


def extension_for_format(fmt: str) -> str:
    return {"md": "md", "tsv": "tsv", "csv": "csv", "html": "html"}[fmt]


def render(
    fmt: str,
    level_name: str,
    template_count_rows: list[list[str]],
    rows: list[list[str]],
    question_summary_rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
    word_freq_rows: list[list[str]],
) -> str:
    if fmt == "md":
        return build_markdown(level_name, template_count_rows, rows, trans)
    if fmt == "tsv":
        return build_tsv(template_count_rows, rows, trans)
    if fmt == "csv":
        return build_csv(template_count_rows, rows, trans)
    if fmt == "html":
        return build_html(
            level_name,
            template_count_rows,
            rows,
            question_summary_rows,
            trans,
            word_freq_rows,
        )
    raise ValueError(fmt)


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "level_folder",
        type=Path,
        help="Level directory containing questions.json (e.g. app/assets/quiz-data/levels/greetings or greetings)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=root / "cursor-claude-common/output",
        help="Directory for output file",
    )
    parser.add_argument(
        "--format",
        choices=("md", "tsv", "csv", "html"),
        default="html",
        help="Output format: html (bordered table in browser), tsv/csv (Excel/Sheets), md (GitHub-style). Default: html.",
    )
    parser.add_argument(
        "--flow",
        type=Path,
        default=root / "app/assets/data/flow/game-flow.json",
        help="Game flow JSON for prior-vocabulary report (default: game-flow.json)",
    )
    parser.add_argument(
        "--csv-dir",
        type=Path,
        default=root / "cursor-claude-common/references/final words",
        help="Final-word CSV folder used to classify prior words by type",
    )
    parser.add_argument(
        "--skip-prior-words",
        action="store_true",
        help="Do not write prior-words-by-type.md",
    )
    parser.add_argument(
        "--skip-final-words",
        action="store_true",
        help="Do not refresh final words/*.csv, LanGeek nouns CSV, or Oxford list",
    )
    parser.add_argument(
        "--dry-run-final-words",
        action="store_true",
        help="Print final-word refresh actions without writing reference files",
    )
    parser.add_argument(
        "--oxford-txt",
        type=Path,
        default=root / "cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt",
        help="Oxford word list to mark when refreshing final-word references",
    )
    parser.add_argument(
        "--skip-oxford-mark",
        action="store_true",
        help="When refreshing final-word references, skip Oxford list marking",
    )
    args = parser.parse_args()

    level_dir = args.level_folder
    if not level_dir.is_absolute():
        level_dir = (root / level_dir).resolve()

    if not level_dir.is_dir():
        print(f"Not a directory: {level_dir}", file=sys.stderr)
        return 1

    questions_path = level_dir / "questions.json"
    translations_path = level_dir / "translations.json"
    if not questions_path.is_file():
        print(f"Missing questions.json in {level_dir}", file=sys.stderr)
        return 1

    level_name = level_dir.name

    with questions_path.open(encoding="utf-8") as f:
        data = json.load(f)
    questions = data.get("levelQuestions")
    if not isinstance(questions, list):
        print(f"Invalid format in {questions_path}: levelQuestions must be an array", file=sys.stderr)
        return 1

    v_errs = validate_level_questions(questions)
    if v_errs:
        print(
            f"Template validation failed for {questions_path} ({len(v_errs)} issue(s)):\n",
            file=sys.stderr,
        )
        for line in v_errs:
            print(f"  {line}", file=sys.stderr)
        return 1

    template_count_rows = collect_template_count_rows(questions)
    translation_words = load_translation_english_words(translations_path)
    rows = collect_rows(questions, translation_words)
    question_summary_rows = collect_question_summary_rows(questions)
    trans = collect_translation_rows(translations_path)
    word_freq_rows = collect_word_frequency_rows(data)
    body = render(
        args.format,
        level_name,
        template_count_rows,
        rows,
        question_summary_rows,
        trans,
        word_freq_rows,
    )

    output_dir = args.output_dir if args.output_dir.is_absolute() else (root / args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    ext = extension_for_format(args.format)
    output_path = output_dir / f"{level_name}-questions.{ext}"
    output_path.write_text(body, encoding="utf-8")
    print(f"Wrote {output_path}")
    if trans:
        print(f"  (includes translations from {translations_path.name})")
    else:
        print(f"  (no translations table: missing or empty {translations_path.name})")

    flow_path = args.flow.resolve()
    levels_root = level_dir.parent
    csv_dir = args.csv_dir.resolve()

    if not args.skip_prior_words:
        write_prior_words_by_type(
            level_name,
            output_dir,
            flow_path=flow_path,
            levels_root=levels_root,
            csv_dir=csv_dir,
        )

    if not args.skip_final_words:
        if refresh_final_word_references is None:
            print(
                "Skip final-word refresh: could not import update_final_word_counts_from_levels",
                file=sys.stderr,
            )
        else:
            oxford_path = (
                args.oxford_txt
                if args.oxford_txt.is_absolute()
                else (root / args.oxford_txt)
            )
            rc = refresh_final_word_references(
                levels_root,
                csv_dir,
                oxford_txt=oxford_path,
                skip_oxford=args.skip_oxford_mark,
                dry_run=args.dry_run_final_words,
            )
            if rc != 0:
                return rc

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
