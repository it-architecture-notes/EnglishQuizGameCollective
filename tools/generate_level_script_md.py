#!/usr/bin/env python3
"""
Generate a plain "script" markdown file for one flavor's levels, in game-flow order — a fast
readthrough of what a level actually says, stripped of quiz mechanics (no answer-choice
buttons, no distractors, no translations).

Per level's `questions.json`, in row order:
  - `VideoConversation` rows: the row's dialogue line(s) only (no answer/distractor).
  - Standalone conversational templates (`DialogueCompletion`, `SentenceBuilder`,
    `ClozeSequence`, `AppearDisappear`, `ConvoTemplate-1`): same dialogue-line extraction,
    no answer/distractor.
  - `imageQuizTemplate-1` / `imageQuizTemplate-2`: question and answer (`imageName` stands in
    for the picture prompt), no wrongAnswers.
  - `WordPairs`: only the English words, comma-joined (no translations).

`Chapter` rows are skipped (no language content).

Dialogue-line extraction prefers each row's own `question_enter_audio_text` /
`question_exit_correct_audio_text` (already-natural spoken text, present on both
`VideoConversation` and standalone rows) and falls back to reconstructing the line(s) from
`questionData` (filling `_____` blanks with `answer`/`answers` in order) when those fields are
absent.

Levels are listed in `app/assets/data/flow/game-flow-{flavor}.json` order (skipping
`kind: "reminder"` entries); any level folder found on disk with a `{flavor}/questions.json`
but not present in the flow file is appended at the end, alphabetically.

Usage:
  python3 tools/generate_level_script_md.py --flavor adults-beginner
  python3 tools/generate_level_script_md.py --flavor adults-intermediate -o all-ai-common/output/adults-intermediate-script.md
  python3 tools/generate_level_script_md.py --flavor kids --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

BLANK_RE = re.compile(r"_{2,}")

_VIDEO_DIALOGUE_ANSWER_TYPES = {
    "DialogueCompletion",
    "SentenceBuilder",
    "ClozeSequence",
    "AppearDisappear",
    "pausedDialogueCompletion",
    "pausedSentenceBuilder",
    "pausedClozeSequence",
}
_STANDALONE_DIALOGUE_TEMPLATES = {
    "DialogueCompletion",
    "SentenceBuilder",
    "ClozeSequence",
    "AppearDisappear",
    "ConvoTemplate-1",
}
_IMAGE_QUIZ_TEMPLATES = {"imageQuizTemplate-1", "imageQuizTemplate-2"}


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _norm(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _str_or_none(value: Any) -> str | None:
    if isinstance(value, str):
        v = value.strip()
        return v or None
    return None


def _text_or_none(value: Any) -> str | None:
    """`question_enter_audio_text` / `question_exit_correct_audio_text`: a plain string, an
    array of strings (joined in order), or the literal `"none"` (treated as absent)."""
    if isinstance(value, str):
        v = value.strip()
        if not v or v.lower() == "none":
            return None
        return v
    if isinstance(value, list):
        parts = [str(x).strip() for x in value if str(x).strip()]
        return _norm(" ".join(parts)) if parts else None
    return None


def _answers_list(qd: dict[str, Any]) -> list[str]:
    raw = qd.get("answer") or qd.get("answers")
    if isinstance(raw, list):
        return [str(x).strip() for x in raw if str(x).strip()]
    if isinstance(raw, str) and raw.strip():
        return [raw.strip()]
    return []

def _fill_blanks(text: str, answers: list[str]) -> str:
    out = text
    for a in answers:
        if not BLANK_RE.search(out):
            break
        out = BLANK_RE.sub(a, out, count=1)
    return _norm(out)


def _join_words(value: Any) -> str | None:
    if isinstance(value, str):
        return _norm(value)
    if isinstance(value, list) and value:
        return _norm(" ".join(str(x) for x in value))
    return None


def _template_label(kind: str, qd: dict[str, Any]) -> str:
    """`` `kind` `` for most rows; ClozeSequence/pausedClozeSequence and ConvoTemplate-1 get
    their blank answer word(s) appended, since those are the two shapes where the graded
    word(s) aren't obvious just from reading the resolved dialogue line."""
    if kind in ("ClozeSequence", "pausedClozeSequence"):
        answers = _answers_list(qd)
        if answers:
            return f"`{kind}` ({', '.join(answers)})"
    elif kind == "ConvoTemplate-1":
        answer = _str_or_none(qd.get("answer"))
        if answer:
            return f"`{kind}` ({answer})"
    return f"`{kind}`"


def _resolve_dialogue(row: dict[str, Any]) -> tuple[str | None, str | None]:
    """Returns (prompt_line, resolved_line) for a VideoConversation or standalone
    conversational-template row. Either may be None (nothing to show for that half)."""
    qd = row.get("questionData")
    qd = qd if isinstance(qd, dict) else {}
    template = str(row.get("template", "")).strip()
    answer_type = str(qd.get("answer_type", "")).strip()

    prompt = _text_or_none(row.get("question_enter_audio_text"))
    resolved = _text_or_none(row.get("question_exit_correct_audio_text"))
    if prompt is None:
        # A blanked line1 (e.g. pausedClozeSequence's "Case B": line1 itself carries a
        # blank) is never presentable as-is — skip the fallback so it doesn't show up
        # raw alongside `resolved`, which (when present) already carries the filled-in
        # line1 text as part of a multi-clip `question_exit_correct_audio_text`.
        raw_line1 = _str_or_none(qd.get("line1"))
        if raw_line1 and not BLANK_RE.search(raw_line1):
            prompt = raw_line1
    if resolved is not None:
        return prompt, resolved

    # Structural fallback when there's no audio-text override at all.
    if template == "ConvoTemplate-1":
        line1 = _str_or_none(qd.get("line1"))
        line2 = _str_or_none(qd.get("line2"))
        answer = _str_or_none(qd.get("answer"))
        if line1 and line2 and answer:
            return _fill_blanks(line1, [answer]), _fill_blanks(line2, [answer])
        return prompt, None

    kind = answer_type or template
    if kind in ("DialogueCompletion", "pausedDialogueCompletion"):
        resolved = _str_or_none(qd.get("answer"))
    elif kind in ("SentenceBuilder", "pausedSentenceBuilder"):
        resolved = _join_words(qd.get("correct_order"))
    elif kind == "AppearDisappear":
        resolved = _join_words(qd.get("words"))
    elif kind in ("ClozeSequence", "pausedClozeSequence"):
        sentence = _str_or_none(qd.get("sentence"))
        line1 = _str_or_none(qd.get("line1"))
        answers = _answers_list(qd)
        if sentence:
            if line1:
                line1_blank_count = len(BLANK_RE.findall(line1))
                prompt = _fill_blanks(line1, answers[:line1_blank_count])
                resolved = _fill_blanks(sentence, answers[line1_blank_count:])
            else:
                resolved = _fill_blanks(sentence, answers)
    return prompt, resolved


def _flow_ordered_level_dirs(levels_root: Path, flow_path: Path) -> list[str]:
    ordered: list[str] = []
    seen: set[str] = set()
    if flow_path.is_file():
        flow = json.loads(flow_path.read_text(encoding="utf-8"))
        for entry in flow:
            if entry.get("kind") == "reminder":
                continue
            name = entry.get("directoryName")
            if name and name not in seen:
                ordered.append(name)
                seen.add(name)
    # Any level folder on disk not covered by the flow file, appended alphabetically.
    for d in sorted(levels_root.iterdir()):
        if d.is_dir() and d.name not in seen and not d.name.startswith("_"):
            ordered.append(d.name)
            seen.add(d.name)
    return ordered


def _level_title(flow_path: Path, directory_name: str) -> str | None:
    if not flow_path.is_file():
        return None
    flow = json.loads(flow_path.read_text(encoding="utf-8"))
    for entry in flow:
        if entry.get("directoryName") == directory_name:
            return entry.get("title")
    return None


def render_level_markdown(level_dir: Path, title: str) -> str | None:
    questions_path = level_dir / "questions.json"
    if not questions_path.is_file():
        return None
    data = json.loads(questions_path.read_text(encoding="utf-8"))
    rows = data.get("levelQuestions", [])

    video_lines: list[str] = []
    standalone_lines: list[str] = []
    image_lines: list[str] = []
    wordpairs_lines: list[str] = []
    current_video_file: str | None = None

    for row in rows:
        template = str(row.get("template", "")).strip()
        if template == "Chapter":
            continue

        if template == "VideoConversation":
            qd = row.get("questionData")
            answer_type = (
                str(qd.get("answer_type", "")).strip() if isinstance(qd, dict) else ""
            )
            if answer_type not in _VIDEO_DIALOGUE_ANSWER_TYPES:
                continue
            prompt, resolved = _resolve_dialogue(row)
            block = "\n".join(l for l in (prompt, resolved) if l)
            if not block:
                continue
            # A `videoFile` change is a hard scene boundary — mark it with a rule + label so
            # it's obvious where one clip's dialogue ends and the next begins.
            video_file = _str_or_none(row.get("videoFile"))
            if video_file != current_video_file:
                if current_video_file is not None:
                    video_lines.append("---")
                if video_file:
                    video_lines.append(f"**{video_file}**")
                current_video_file = video_file
            video_lines.append(f"{_template_label(answer_type, qd)}\n{block}")
            continue

        if template in _STANDALONE_DIALOGUE_TEMPLATES:
            prompt, resolved = _resolve_dialogue(row)
            block = "\n".join(l for l in (prompt, resolved) if l)
            if block:
                row_qd = row.get("questionData")
                row_qd = row_qd if isinstance(row_qd, dict) else {}
                standalone_lines.append(f"{_template_label(template, row_qd)}\n{block}")
            continue

        if template in _IMAGE_QUIZ_TEMPLATES:
            qd = row.get("questionData")
            qd = qd if isinstance(qd, dict) else {}
            question = _str_or_none(qd.get("imageName"))
            answer = _str_or_none(qd.get("answer")) or question
            if question and answer:
                image_lines.append(f"{question} → {answer}")
            continue

        if template == "WordPairs":
            qd = row.get("questionData")
            qd = qd if isinstance(qd, dict) else {}
            words = qd.get("english_words")
            if isinstance(words, list) and words:
                wordpairs_lines.append(", ".join(str(w).strip() for w in words))
            continue

    if not (video_lines or standalone_lines or image_lines or wordpairs_lines):
        return None

    out = [f"## {title}\n"]
    if video_lines:
        out.append("### Video Dialogue\n")
        out.append("\n\n".join(video_lines) + "\n")
    if standalone_lines:
        out.append("### Standalone Dialogue\n")
        out.append("\n\n".join(standalone_lines) + "\n")
    if image_lines:
        out.append("### Picture Vocabulary\n")
        out.append("\n".join(f"- {l}" for l in image_lines) + "\n")
    if wordpairs_lines:
        out.append("### Word Pairs\n")
        out.append("\n".join(f"- {l}" for l in wordpairs_lines) + "\n")
    return "\n".join(out)


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--flavor",
        choices=["kids", "adults-intermediate", "adults-beginner"],
        default="adults-beginner",
    )
    parser.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
    )
    parser.add_argument("--output", "-o", type=Path, default=None)
    parser.add_argument("--dry-run", action="store_true", help="Print to stdout only")
    args = parser.parse_args()

    flow_path = root / "app/assets/data/flow" / f"game-flow-{args.flavor}.json"
    levels_root: Path = args.levels_root.resolve()
    directory_names = _flow_ordered_level_dirs(levels_root, flow_path)

    sections: list[str] = [f"# {args.flavor} Level Script\n"]
    levels_included = 0
    for directory_name in directory_names:
        level_dir = levels_root / directory_name / args.flavor
        title = _level_title(flow_path, directory_name) or directory_name
        section = render_level_markdown(level_dir, title)
        if section:
            sections.append(section)
            levels_included += 1

    content = "\n".join(sections).rstrip() + "\n"

    if args.dry_run:
        print(content)
        print(f"\n[dry-run] {levels_included} levels included.", file=sys.stderr)
        return 0

    out_path = args.output or (
        root / "all-ai-common/output" / f"{args.flavor}-level-script.md"
    )
    if not out_path.is_absolute():
        out_path = (root / out_path).resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    print(f"Wrote {out_path} ({levels_included} levels).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
