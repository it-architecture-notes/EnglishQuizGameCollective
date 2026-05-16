#!/usr/bin/env python3
"""
Broader companion to `tools/global_game_word_frequency.py`: same scanning and CSV
shape, but reads additional `questionData` text fields from non–image-template
questions.

**questions.json**
  1. Skip entire question objects whose `template` (after strip) starts with `imageQuizTemplate`.
  2. From `questionData`, read:
     - `words`, `answers`, `answer`, `english_words`, `correct_order` — string,
       array of strings, or scalar coerced to string (flatten lists like
       `update_final_word_counts_from_levels.py`).
     - `line1`, `line2`, `sentence` — plain string, or legacy `{"en": "..."}`;
       only the `en` value is taken when the value is a dict.
     For `GrammarForm`, `questionData.answer` is **not** counted.
  3. `WordPairs` / legacy `ConvoTemplate-WordPairs`: `english_words` is always
     appended again so left-column English is counted.

**translations.json**
  - Only `english_word` in each `translations_list` entry.

Default output filename contains `big_scope` (see `--output`).

Tokenization / optional NLTK `word_type`: same as `global_game_word_frequency.py`.

Usage:
  python3 tools/global_game_word_frequency_big_scope.py
  python3 tools/global_game_word_frequency_big_scope.py --output /tmp/words-big.csv

Install tagging (optional):
  pip install nltk && python3 -c "import nltk; nltk.download('punkt'); nltk.download('averaged_perceptron_tagger_eng')"
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

TOKEN_RE = re.compile(r"[a-z0-9]+(?:[-'][a-z0-9]+)*", re.IGNORECASE)

# list-or-string flatteners (words, answers, answer, english_words, correct_order)
_QUESTION_DATA_LIST_OR_STRING_KEYS = frozenset(
    {"words", "answers", "answer", "english_words", "correct_order"}
)

# line / sentence fields may be string or {"en": "..."}
_LINE_OR_SENTENCE_KEYS = frozenset({"line1", "line2", "sentence"})

_WORD_PAIRS_TEMPLATE_IDS = frozenset({"WordPairs", "ConvoTemplate-WordPairs"})


def _template_str(raw) -> str:
    return raw.strip() if isinstance(raw, str) else ""


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def append_scalar_blobs(raw, blobs: list[str]) -> None:
    if raw is None:
        return
    if isinstance(raw, list):
        for item in raw:
            append_scalar_blobs(item, blobs)
        return
    s = str(raw).strip()
    if s:
        blobs.append(s)


def append_line_or_sentence_blobs(raw, blobs: list[str]) -> None:
    """line1 / line2 / sentence: allow legacy locale map with `en` only."""
    if raw is None:
        return
    if isinstance(raw, str):
        s = raw.strip()
        if s:
            blobs.append(s)
        return
    if isinstance(raw, dict):
        en = raw.get("en")
        if en is not None:
            s = str(en).strip()
            if s:
                blobs.append(s)
        return
    append_scalar_blobs(raw, blobs)


def extract_text_blobs_from_question(item: dict) -> list[str]:
    blobs: list[str] = []
    if not isinstance(item, dict):
        return blobs
    tpl = _template_str(item.get("template"))
    if tpl.startswith("imageQuizTemplate"):
        return blobs
    qd = item.get("questionData")
    if not isinstance(qd, dict):
        return blobs
    for key in _QUESTION_DATA_LIST_OR_STRING_KEYS:
        if key == "answer" and tpl == "GrammarForm":
            continue
        if key in qd:
            append_scalar_blobs(qd[key], blobs)
    for key in _LINE_OR_SENTENCE_KEYS:
        if key in qd:
            append_line_or_sentence_blobs(qd[key], blobs)
    if tpl in _WORD_PAIRS_TEMPLATE_IDS:
        append_scalar_blobs(qd.get("english_words"), blobs)
    return blobs


def extract_text_blobs_from_translations(data: dict) -> list[str]:
    blobs: list[str] = []
    lst = data.get("translations_list")
    if not isinstance(lst, list):
        return blobs
    for entry in lst:
        if not isinstance(entry, dict):
            continue
        ew = entry.get("english_word")
        if ew is None:
            continue
        s = str(ew).strip()
        if s:
            blobs.append(s)
    return blobs


def tokenize_lower(text: str) -> list[str]:
    return [m.group(0).lower() for m in TOKEN_RE.finditer(text or "")]


def _penn_to_coarse(tag: str) -> str:
    if not tag:
        return "other"
    if tag.startswith("NN"):
        return "noun"
    if tag.startswith("VB"):
        return "verb"
    if tag.startswith("JJ"):
        return "adjective"
    if tag.startswith("RB"):
        return "adverb"
    if tag in ("DT", "IN", "TO", "CC", "WDT", "WP", "WP$", "WRB") or tag.startswith(
        ("PRP", "PRP$", "MD", "RP", "EX", "PDT")
    ):
        pass
    return "other"


def try_import_nltk_pos():
    try:
        import nltk  # noqa: F401
        from nltk import pos_tag
    except ImportError:
        return None, None
    return nltk, pos_tag


def tag_tokens_in_blob(blob: str) -> list[tuple[str, str]]:
    _, pos_tag = try_import_nltk_pos()
    if pos_tag is None or not blob:
        return []

    matches = list(TOKEN_RE.finditer(blob))
    if not matches:
        return []

    raw_pieces = [m.group(0) for m in matches]
    try:
        tagged = pos_tag(raw_pieces)
    except LookupError:
        return []
    except Exception:
        return []

    out: list[tuple[str, str]] = []
    for i, m in enumerate(matches):
        if i < len(tagged):
            _, penn = tagged[i]
            coarse = _penn_to_coarse(penn)
        else:
            coarse = "other"
        out.append((m.group(0).lower(), coarse))
    return out


def feed_blobs_into_counters(
    blobs: list[str],
    word_counts: Counter[str],
    type_votes: dict[str, Counter[str]],
    nltk_available: bool,
) -> None:
    for blob in blobs:
        for tok in tokenize_lower(blob):
            word_counts[tok] += 1
        if nltk_available:
            for tok, coarse in tag_tokens_in_blob(blob):
                type_votes[tok][coarse] += 1


def iter_rglob(root: Path, name: str) -> list[Path]:
    return sorted(p for p in root.rglob(name) if p.is_file())


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
        help="Root folder to scan for questions.json and translations.json",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "cursor-claude-common/output/global-game-word-frequency-big_scope.csv",
        help="Output CSV path (default includes 'big_scope' in the filename)",
    )
    args = parser.parse_args()

    levels_root = args.levels_root
    if not levels_root.is_absolute():
        levels_root = (root / levels_root).resolve()
    if not levels_root.is_dir():
        print(f"Not a directory: {levels_root}", file=sys.stderr)
        return 1

    output_path = args.output
    if not output_path.is_absolute():
        output_path = (root / output_path).resolve()

    word_counts: Counter[str] = Counter()
    type_votes: dict[str, Counter[str]] = defaultdict(Counter)
    nltk_available = try_import_nltk_pos()[1] is not None

    q_files = iter_rglob(levels_root, "questions.json")
    t_files = iter_rglob(levels_root, "translations.json")
    if not q_files and not t_files:
        print(f"No questions.json or translations.json under {levels_root}", file=sys.stderr)
        return 1

    for path in q_files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as e:
            print(f"Skip {path}: {e}", file=sys.stderr)
            continue
        rows = data.get("levelQuestions")
        if not isinstance(rows, list):
            continue
        for item in rows:
            if not isinstance(item, dict):
                continue
            feed_blobs_into_counters(
                extract_text_blobs_from_question(item),
                word_counts,
                type_votes,
                nltk_available,
            )

    for path in t_files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as e:
            print(f"Skip {path}: {e}", file=sys.stderr)
            continue
        feed_blobs_into_counters(
            extract_text_blobs_from_translations(data),
            word_counts,
            type_votes,
            nltk_available,
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    header = ["word", "word_type", "count"]
    sorted_words = sorted(word_counts.items(), key=lambda kv: (-kv[1], kv[0]))

    with output_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        for word, count in sorted_words:
            if nltk_available and word in type_votes:
                w_type = type_votes[word].most_common(1)[0][0]
            else:
                w_type = ""
            w.writerow([word, w_type, count])

    print(
        f"Wrote {output_path} ({len(sorted_words)} distinct words from "
        f"{len(q_files)} questions.json, {len(t_files)} translations.json)"
    )
    if not nltk_available:
        print(
            "  word_type column empty (install nltk + tagger data; see docstring).",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
