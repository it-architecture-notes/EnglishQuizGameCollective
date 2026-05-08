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

Before writing output, every question is checked against template rules from
`page-designs-and-templates.md` and `app/lib/models/level_config.dart` (required
fields, counts, Cloze blank/answer alignment — blanks may use trailing `.` `!`
`?` etc. on the same token — WordPairs pair count, split audio pairing,
translation fields not misplaced at question root). Any violation
prints all errors and exits with code 1.

Questions table columns:
  - English (translate): questionData.english_to_translate (English strings only)
  - Audio: top-level audio_file, audio_file1, audio_file2 when present

Translations table (only if translations.json exists and has translations_list):
  - #: row index
  - English word: english_word
  - One column per locale code found across all rows (sorted), values from translations[locale]
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import sys
from pathlib import Path

TABLE_HEADERS = [
    "#",
    "Template",
    "Line 1 / Prompt",
    "Line 2",
    "Answer",
    "English (translate)",
    "Audio",
]

# Templates accepted by app/lib/models/level_config.dart _parseQuestion switch.
_KNOWN_TEMPLATES = frozenset(
    {
        "imageQuizTemplate-1",
        "imageQuizTemplate-2",
        "imageQuizTemplate-3",
        "imageQuizTemplate-SentenceChoice",
        "ConvoTemplate-1",
        "AppearDisappear",
        "ClozeSequence",
        "SentenceBuilder",
        "WordPairs",
        "GrammarForm",
        "DialogueCompletion",
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


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def normalize_template(template: str) -> str:
    if template in ("imageQuizTemplate-3", "imageQuizTemplate-SentenceChoice"):
        return "imageQuizTemplate-1"
    return template or "unknown"


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

    if template in (
        "imageQuizTemplate-1",
        "imageQuizTemplate-3",
        "imageQuizTemplate-SentenceChoice",
    ):
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
        if n < 3 or n > 4:
            errs.append(
                f"{prefix} (WordPairs): expect 3–4 pairs, got {n}"
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


def summarize_row(template: str, question_data: dict) -> tuple[str, str, str]:
    tpl = normalize_template(template)

    if tpl == "imageQuizTemplate-1":
        image_name = (question_data.get("imageName") or "").strip()
        answer = (question_data.get("answer") or image_name or "").strip()
        return (f"image: {image_name}" if image_name else "(no image)", "", answer)

    if tpl == "imageQuizTemplate-2":
        image_name = (question_data.get("imageName") or "").strip()
        answer = (question_data.get("answer") or image_name or "").strip()
        return (f"image: {image_name}" if image_name else "(no image)", "", answer)

    if tpl == "ConvoTemplate-1":
        return (
            str(question_data.get("line1", "")),
            str(question_data.get("line2", "")),
            str(question_data.get("answer", "")),
        )

    if tpl == "DialogueCompletion":
        return (str(question_data.get("line1", "")), "", str(question_data.get("answer", "")))

    if tpl == "AppearDisappear":
        words = words_from_array_or_sentence(question_data.get("words"))
        line1 = " ".join(words) if words else str(question_data.get("words", ""))
        return (line1, "", "-")

    if tpl == "ClozeSequence":
        sentence = str(question_data.get("sentence", ""))
        raw_answer = question_data.get("answer")
        if raw_answer is None:
            raw_answer = question_data.get("answers")
        if isinstance(raw_answer, list):
            answer = ", ".join(str(x) for x in raw_answer)
        else:
            answer = str(raw_answer or "")
        return (sentence, "", answer)

    if tpl == "SentenceBuilder":
        correct_order = question_data.get("correct_order")
        if isinstance(correct_order, list):
            sentence = " ".join(str(x) for x in correct_order)
        else:
            sentence = str(correct_order or "").strip()
        return (sentence, "", sentence)

    if tpl == "WordPairs":
        words = question_data.get("english_words")
        if isinstance(words, list):
            line1 = "; ".join(str(x) for x in words)
        else:
            line1 = str(words or "")
        return (line1, "word pairs", "match all pairs")

    if tpl == "GrammarForm":
        sentence = str(question_data.get("sentence", ""))
        raw_answer = question_data.get("answer")
        if isinstance(raw_answer, list):
            answer = ", ".join(str(x) for x in raw_answer)
        else:
            answer = str(raw_answer or "")
        return (sentence, "", answer)

    return (f"(unsupported template {template})", "", "")


def english_translate_cell(question_data: dict) -> str:
    """questionData.english_to_translate — English-only strings for translation reveal."""
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


def collect_rows(questions: list) -> list[list[str]]:
    """One data row = seven plain strings (no format-specific escaping)."""
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
        en_tr = english_translate_cell(question_data)
        audio = audio_files_cell(item)
        rows.append(
            [
                str(index),
                normalize_template(template),
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
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    lines = [
        f"# {level_name} questions",
        "",
        f"## {level_name} — questions",
        "",
        "| " + " | ".join(TABLE_HEADERS) + " |",
        "|" + "|".join(["---:"] + ["---"] * (len(TABLE_HEADERS) - 1)) + "|",
    ]
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
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    out_lines = ["\t".join(tsv_cell(h) for h in TABLE_HEADERS)]
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
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    import io

    buf = io.StringIO(newline="")
    w = csv.writer(buf)
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


def _html_table(headers: list[str], data_rows: list[list[str]]) -> str:
    thead = "<thead><tr>" + "".join(f"<th>{html.escape(h)}</th>" for h in headers) + "</tr></thead>"
    body_rows = []
    for r in data_rows:
        tds = "".join(f"<td>{html.escape(c)}</td>" for c in r)
        body_rows.append(f"<tr>{tds}</tr>")
    tbody = "<tbody>" + "".join(body_rows) + "</tbody>"
    return f"<table>\n{thead}\n{tbody}\n</table>"


def build_html(
    level_name: str,
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
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
    """
    q_table = _html_table(TABLE_HEADERS, rows)
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
  <div class="wrap">
    {q_table}
  </div>
{trans_block}
</body>
</html>
"""


def extension_for_format(fmt: str) -> str:
    return {"md": "md", "tsv": "tsv", "csv": "csv", "html": "html"}[fmt]


def render(
    fmt: str,
    level_name: str,
    rows: list[list[str]],
    trans: tuple[list[str], list[list[str]]] | None,
) -> str:
    if fmt == "md":
        return build_markdown(level_name, rows, trans)
    if fmt == "tsv":
        return build_tsv(rows, trans)
    if fmt == "csv":
        return build_csv(rows, trans)
    if fmt == "html":
        return build_html(level_name, rows, trans)
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

    rows = collect_rows(questions)
    trans = collect_translation_rows(translations_path)
    body = render(args.format, level_name, rows, trans)

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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
