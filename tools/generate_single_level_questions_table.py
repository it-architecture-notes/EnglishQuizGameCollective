#!/usr/bin/env python3
"""
Generate a markdown table for a single level questions.json file.

Usage:
  python3 tools/generate_single_level_questions_table.py \
    app/assets/quiz-data/levels/greetings/questions.json

Output:
  cursor-claude-common/output/<level-name>-questions.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def normalize_template(template: str) -> str:
    if template in ("imageQuizTemplate-3", "imageQuizTemplate-SentenceChoice"):
        return "imageQuizTemplate-1"
    return template or "unknown"


def escape_cell(value: str) -> str:
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

    if tpl == "ConvoTemplate-DialogueCompletion":
        return (str(question_data.get("line1", "")), "", str(question_data.get("answer", "")))

    if tpl == "ConvoTemplate-AppearDisappear":
        words = words_from_array_or_sentence(question_data.get("words"))
        line1 = " ".join(words) if words else str(question_data.get("words", ""))
        return (line1, "", "-")

    if tpl == "ConvoTemplate-ClozeSequence":
        sentence = str(question_data.get("sentence", ""))
        raw_answer = question_data.get("answer")
        if raw_answer is None:
            raw_answer = question_data.get("answers")
        if isinstance(raw_answer, list):
            answer = ", ".join(str(x) for x in raw_answer)
        else:
            answer = str(raw_answer or "")
        return (sentence, "", answer)

    if tpl == "ConvoTemplate-SentenceBuilder":
        correct_order = question_data.get("correct_order")
        if isinstance(correct_order, list):
            sentence = " ".join(str(x) for x in correct_order)
        else:
            sentence = str(correct_order or "").strip()
        return (sentence, "", sentence)

    if tpl == "ConvoTemplate-WordPairs":
        words = question_data.get("english_words")
        if isinstance(words, list):
            line1 = "; ".join(str(x) for x in words)
        else:
            line1 = str(words or "")
        return (line1, "word pairs", "match all pairs")

    if tpl == "ConvoTemplate-GrammarForm":
        sentence = str(question_data.get("sentence", ""))
        raw_answer = question_data.get("answer")
        if isinstance(raw_answer, list):
            answer = ", ".join(str(x) for x in raw_answer)
        else:
            answer = str(raw_answer or "")
        return (sentence, "", answer)

    return (f"(unsupported template {template})", "", "")


def build_markdown(level_name: str, questions: list) -> str:
    lines = [
        f"# {level_name} questions",
        "",
        f"## {level_name}",
        "",
        "| # | Template | Line 1 / Prompt | Line 2 | Answer |",
        "|---:|---|---|---|---|",
    ]

    for index, item in enumerate(questions, start=1):
        if not isinstance(item, dict):
            lines.append(f"| {index} | (invalid) | (not an object) |  |  |")
            continue
        template = str(item.get("template", ""))
        question_data = item.get("questionData")
        if not isinstance(question_data, dict):
            lines.append(
                f"| {index} | {escape_cell(template)} | (missing questionData) |  |  |"
            )
            continue

        line1, line2, answer = summarize_row(template, question_data)
        lines.append(
            f"| {index} | {escape_cell(normalize_template(template))} | "
            f"{escape_cell(line1)} | {escape_cell(line2)} | {escape_cell(answer)} |"
        )

    lines.append("")
    return "\n".join(lines)


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("questions_json", type=Path, help="Path to one questions.json file")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=root / "cursor-claude-common/output",
        help="Directory where <level-name>-questions.md is written",
    )
    args = parser.parse_args()

    questions_path = args.questions_json
    if not questions_path.is_absolute():
        questions_path = (root / questions_path).resolve()

    if not questions_path.is_file():
        print(f"File not found: {questions_path}", file=sys.stderr)
        return 1
    if questions_path.name != "questions.json":
        print(f"Expected a questions.json file, got: {questions_path.name}", file=sys.stderr)
        return 1

    level_name = questions_path.parent.name

    with questions_path.open(encoding="utf-8") as f:
        data = json.load(f)
    questions = data.get("levelQuestions")
    if not isinstance(questions, list):
        print(f"Invalid format in {questions_path}: levelQuestions must be an array", file=sys.stderr)
        return 1

    markdown = build_markdown(level_name, questions)
    output_dir = args.output_dir if args.output_dir.is_absolute() else (root / args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{level_name}-questions.md"
    output_path.write_text(markdown, encoding="utf-8")
    print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

