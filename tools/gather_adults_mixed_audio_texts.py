#!/usr/bin/env python3
"""
Dump spoken/audio base texts for every non-image question in adult mixed levels.

Reads ``app/assets/data/flow/game-flow.json`` (skips reminders + titles marked
"Image only"), then each level's ``adults/questions.json`` (falls back to root
``questions.json``).

Blanks (``___`` / ``_____``) are filled with the correct answer — the same
resolved strings used as TTS input. Dual-audio templates list each clip text
separately.

Usage:
  python3 tools/gather_adults_mixed_audio_texts.py
  python3 tools/gather_adults_mixed_audio_texts.py --format json
  python3 tools/gather_adults_mixed_audio_texts.py -o somewhere/else.md

Output (default):
  cursor-claude-common/output/adults-mixed-audio-base-texts.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BLANK_RE = re.compile(r"_{2,}")

_IMAGE_TEMPLATES = {
    "imageQuizTemplate-1",
    "imageQuizTemplate-2",
    "imageQuizTemplate-3",
    "imageQuizTemplate-SentenceChoice",
    "imageQuizTemplate-SpotDifference",
}


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def is_image_only_title(title: str) -> bool:
    return "image only" in (title or "").lower()


def load_flow_levels(flow_path: Path) -> list[tuple[int, str, str]]:
    """Ordered [(mainLevel, directoryName, title), ...]; reminders + image-only skipped."""
    data = json.loads(flow_path.read_text(encoding="utf-8"))
    seen: set[tuple[int, str]] = set()
    out: list[tuple[int, str, str]] = []
    for entry in data:
        if not isinstance(entry, dict) or entry.get("kind") == "reminder":
            continue
        name = entry.get("directoryName")
        ml = entry.get("mainLevel")
        title = entry.get("title") or ""
        if not isinstance(name, str) or not name.strip() or not isinstance(ml, int):
            continue
        if is_image_only_title(str(title)):
            continue
        key = (ml, name)
        if key in seen:
            continue
        seen.add(key)
        out.append((ml, name, str(title)))
    return out


def load_questions(levels_root: Path, directory_name: str) -> list[dict] | None:
    adults_path = levels_root / directory_name / "adults" / "questions.json"
    root_path = levels_root / directory_name / "questions.json"
    path = adults_path if adults_path.is_file() else root_path
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    rows = data.get("levelQuestions")
    return rows if isinstance(rows, list) else None


def _str_or_none(value) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        s = value.strip()
        return s if s else None
    return None


def _localized_en(value) -> str | None:
    if isinstance(value, str):
        return _str_or_none(value)
    if isinstance(value, dict):
        return _str_or_none(value.get("en"))
    return None


def _normalize_spoken_line(text: str) -> str:
    t = re.sub(r"\s+", " ", text).strip()
    t = re.sub(r"\s+([,.;!?])", r"\1", t)
    return t


def _replace_blanks_with_answer(text: str, answer: str | None) -> str:
    if answer and answer.strip():
        return BLANK_RE.sub(answer.strip(), text)
    return text


def _cloze_answers_list(qd: dict) -> list[str]:
    raw = qd.get("answer") or qd.get("answers")
    if isinstance(raw, list):
        return [str(x).strip() for x in raw if str(x).strip()]
    if isinstance(raw, str):
        return [raw.strip()] if raw.strip() else []
    return []


def _replace_blanks_sequential(text: str, answers: list[str]) -> str:
    out = text
    for ans in answers:
        if not BLANK_RE.search(out):
            break
        out = BLANK_RE.sub(ans, out, count=1)
    return out


def _words_list(value) -> list[str]:
    if isinstance(value, str):
        return [x for x in value.strip().split() if x]
    if not isinstance(value, list):
        return []
    return [str(x).strip() for x in value if str(x).strip()]


def _join_words(value) -> str | None:
    out = _words_list(value)
    return " ".join(out) if out else None


def extract_audio_texts(row: dict) -> dict | None:
    """Returns audio-base texts for one non-image question, blanks filled."""
    template = str(row.get("template", "")).strip()
    if template in _IMAGE_TEMPLATES:
        return None
    qd = row.get("questionData")
    if not isinstance(qd, dict):
        return None

    out: dict = {
        "template": template,
        "genders": row.get("genders") or "",
        "clips": [],
    }

    af = _str_or_none(row.get("audio_file"))
    af1 = _str_or_none(row.get("audio_file1"))
    af2 = _str_or_none(row.get("audio_file2"))
    af_text = _str_or_none(row.get("audio_file_text"))
    af1_text = _str_or_none(row.get("audio_file1_text"))
    af2_text = _str_or_none(row.get("audio_file2_text"))

    if template == "ConvoTemplate-1":
        line1 = _localized_en(qd.get("line1")) or ""
        line2 = _localized_en(qd.get("line2")) or ""
        answer = _str_or_none(qd.get("answer"))
        line1_f = _normalize_spoken_line(_replace_blanks_with_answer(line1, answer))
        line2_f = _normalize_spoken_line(_replace_blanks_with_answer(line2, answer))
        text1 = af1_text or line1_f
        text2 = af2_text or line2_f
        if af1 and af2:
            out["clips"] = [
                {"stem": af1, "text": text1},
                {"stem": af2, "text": text2},
            ]
        elif af:
            out["clips"] = [
                {
                    "stem": af,
                    "text": af_text
                    or f"{text1}\n{text2}",
                }
            ]
        else:
            out["clips"] = [
                {"stem": "", "text": text1},
                {"stem": "", "text": text2},
            ]

    elif template == "DialogueCompletion":
        line1 = _localized_en(qd.get("line1")) or ""
        answer = _str_or_none(qd.get("answer")) or ""
        answer_f = _normalize_spoken_line(
            _replace_blanks_with_answer(answer, None)
            if BLANK_RE.search(answer)
            else answer
        )
        # DialogueCompletion TTS uses answer as-is (blanks -> pause), but user
        # asked for filled correct text when the answer itself is complete.
        text1 = af1_text or line1
        text2 = af2_text or answer_f
        if af1 and af2:
            out["clips"] = [
                {"stem": af1, "text": text1},
                {"stem": af2, "text": text2},
            ]
        else:
            out["clips"] = [
                {"stem": af1 or "", "text": text1},
                {"stem": af2 or "", "text": text2},
            ]

    elif template == "ClozeSequence":
        sentence = _localized_en(qd.get("sentence")) or ""
        filled = _normalize_spoken_line(
            _replace_blanks_sequential(sentence, _cloze_answers_list(qd))
        )
        text = af_text or filled
        out["clips"] = [{"stem": af or "", "text": text}]

    elif template == "SentenceBuilder":
        text = af_text or _join_words(qd.get("correct_order")) or ""
        out["clips"] = [{"stem": af or "", "text": text}]

    elif template == "AppearDisappear":
        text = af_text or _join_words(qd.get("words")) or ""
        out["clips"] = [{"stem": af or "", "text": text}]

    elif template == "GrammarForm":
        sentence = _localized_en(qd.get("sentence")) or ""
        answer = _str_or_none(qd.get("answer"))
        filled = _normalize_spoken_line(_replace_blanks_with_answer(sentence, answer))
        text = af_text or filled
        out["clips"] = [{"stem": af or "", "text": text}]

    elif template == "WordPairs":
        # No sentence/dialog audio; skip.
        return None

    else:
        # Unknown template: surface anything that looks like spoken content.
        bits = []
        for key in ("line1", "line2", "sentence", "answer", "words", "correct_order"):
            v = qd.get(key)
            if v:
                bits.append(f"{key}: {v}")
        if not bits:
            return None
        out["clips"] = [{"stem": af or "", "text": " | ".join(str(b) for b in bits)}]

    # Drop empty-text rows
    out["clips"] = [c for c in out["clips"] if (c.get("text") or "").strip()]
    if not out["clips"]:
        return None
    return out


def gather(levels_root: Path, flow_path: Path) -> list[dict]:
    out: list[dict] = []
    for main_level, level_name, title in load_flow_levels(flow_path):
        rows = load_questions(levels_root, level_name)
        if rows is None:
            continue
        extracted = [
            r for r in (extract_audio_texts(row) for row in rows) if r is not None
        ]
        if not extracted:
            continue
        out.append(
            {
                "mainLevel": main_level,
                "level": level_name,
                "title": title,
                "questions": extracted,
            }
        )
    return out


def render_markdown(sections: list[dict]) -> str:
    lines = [
        "# Adults mixed levels — audio base texts",
        "",
        "Non-image questions only. Image-only flow levels and WordPairs skipped.",
        "Blanks filled with the correct answer (TTS source strings).",
        "",
    ]
    current_ml: int | None = None
    for section in sections:
        ml = section["mainLevel"]
        if ml != current_ml:
            lines.append(f"## Main Level {ml}")
            lines.append("")
            current_ml = ml
        title = section.get("title") or section["level"]
        lines.append(f"### {section['level']} — {title}")
        lines.append("")
        for i, q in enumerate(section["questions"], start=1):
            header = f"**{i}. {q['template']}**"
            if q.get("genders"):
                header += f" _(genders: {q['genders']})_"
            lines.append(header)
            for clip in q["clips"]:
                text = (clip.get("text") or "").strip()
                if text:
                    lines.append(f"- {text}")
            lines.append("")
    return "\n".join(lines) + "\n"


def render_json(sections: list[dict]) -> str:
    return json.dumps(sections, indent=2, ensure_ascii=False) + "\n"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    root = repo_root()
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
    )
    p.add_argument(
        "--flow",
        type=Path,
        default=root / "app/assets/data/flow/game-flow.json",
    )
    p.add_argument("--format", choices=("md", "json"), default="md")
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Default: cursor-claude-common/output/adults-mixed-audio-base-texts.<ext>",
    )
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    root = repo_root()

    sections = gather(args.levels_root.resolve(), args.flow.resolve())

    ext = "md" if args.format == "md" else "json"
    output_path = args.output or (
        root / "cursor-claude-common/output" / f"adults-mixed-audio-base-texts.{ext}"
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)

    body = render_markdown(sections) if args.format == "md" else render_json(sections)
    output_path.write_text(body, encoding="utf-8")

    total_questions = sum(len(s["questions"]) for s in sections)
    total_clips = sum(
        len(q["clips"]) for s in sections for q in s["questions"]
    )
    print(
        f"Wrote {output_path} — {len(sections)} mixed levels, "
        f"{total_questions} questions, {total_clips} audio texts",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
