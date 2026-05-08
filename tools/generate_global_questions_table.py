#!/usr/bin/env python3
"""
Build markdown tables (same shape as cursor-claude-common/output/global-questions.md)
from quiz level JSON files.

Default: scans app/assets/quiz-data/levels/*/questions.json, writes
cursor-claude-common/output/global-questions.md.

Any existing ## <level-folder-name> section is replaced; other ## sections
(e.g. manual notes) are kept after the generated level blocks.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def escape_cell(s: str) -> str:
    if not s:
        return ""
    s = str(s).replace("\r", " ").replace("\n", " ")
    return s.replace("|", "\\|")


def words_from_array_or_sentence(v) -> list[str]:
    if isinstance(v, list):
        return [str(x) for x in v]
    if isinstance(v, str):
        t = v.strip()
        if not t:
            return []
        return re.split(r"\s+", t)
    return []


def normalize_template(t: str) -> str:
    if t in ("imageQuizTemplate-3", "imageQuizTemplate-SentenceChoice"):
        return "imageQuizTemplate-1"
    return t or "unknown"


def summarize_row(template: str, qd: dict) -> tuple[str, str, str]:
    """Return (line1, line2, answer)."""
    tpl = normalize_template(template)

    if tpl == "imageQuizTemplate-1":
        im = (qd.get("imageName") or qd.get("image_name") or "").strip()
        ans = (qd.get("answer") or im or "").strip()
        line1 = f"image: {im}" if im else "(no image)"
        return line1, "", ans

    if tpl == "imageQuizTemplate-2":
        im = (qd.get("imageName") or "").strip()
        ans = (qd.get("answer") or qd.get("imageName") or "").strip()
        line1 = f"image: {im}" if im else "(no image)"
        return line1, "", ans

    if tpl == "ConvoTemplate-1":
        return (
            str(qd.get("line1", "") or ""),
            str(qd.get("line2", "") or ""),
            str(qd.get("answer", "") or ""),
        )

    if tpl == "DialogueCompletion":
        return str(qd.get("line1", "") or ""), "", str(qd.get("answer", "") or "")

    if tpl == "AppearDisappear":
        w = words_from_array_or_sentence(qd.get("words"))
        line1 = " ".join(w) if w else str(qd.get("words") or "")
        return line1, "", "-"

    if tpl == "ClozeSequence":
        sent = str(qd.get("sentence", "") or "")
        raw = qd.get("answer")
        if raw is None:
            raw = qd.get("answers")
        if isinstance(raw, list):
            ans = ", ".join(str(x) for x in raw)
        else:
            ans = str(raw or "")
        return sent, "", ans

    if tpl == "SentenceBuilder":
        co = qd.get("correct_order")
        if isinstance(co, list):
            sentence = " ".join(str(x) for x in co)
        else:
            sentence = str(co or "").strip()
        return sentence, "", sentence

    if tpl == "WordPairs":
        words = qd.get("english_words")
        if isinstance(words, list):
            line1 = "; ".join(str(x) for x in words)
        else:
            line1 = str(words or "")
        return line1, "word pairs", "match all pairs"

    if tpl == "GrammarForm":
        sent = str(qd.get("sentence", "") or "")
        a = qd.get("answer")
        if isinstance(a, list):
            ans = ", ".join(str(x) for x in a)
        else:
            ans = str(a or "")
        return sent, "", ans

    return f"(unsupported template {template})", "", ""


def render_table_for_level(level_name: str, questions: list) -> str:
    lines = [
        f"## {level_name}",
        "",
        "| # | Template | Line 1 / Prompt | Line 2 | Answer |",
        "|---:|---|---|---|---|",
    ]
    for i, q in enumerate(questions, start=1):
        if not isinstance(q, dict):
            lines.append(f"| {i} | (invalid) | (not an object) |  |  |")
            continue
        template = str(q.get("template", ""))
        qd = q.get("questionData")
        if not isinstance(qd, dict):
            lines.append(
                f"| {i} | {escape_cell(template)} | (missing questionData) |  |  |"
            )
            continue
        try:
            l1, l2, ans = summarize_row(template, qd)
            disp_tpl = normalize_template(template)
            lines.append(
                f"| {i} | {escape_cell(disp_tpl)} | {escape_cell(l1)} | "
                f"{escape_cell(l2)} | {escape_cell(ans)} |"
            )
        except Exception as e:
            lines.append(
                f"| {i} | {escape_cell(template)} | {escape_cell(str(e))} |  |  |"
            )
    lines.append("")
    return "\n".join(lines)


def collect_levels(levels_root: Path) -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []
    if not levels_root.is_dir():
        return out
    for p in sorted(levels_root.iterdir(), key=lambda x: x.name.casefold()):
        if not p.is_dir():
            continue
        qj = p / "questions.json"
        if qj.is_file():
            out.append((p.name, qj))
    return out


def load_questions(path: Path) -> list:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    lq = data.get("levelQuestions")
    if not isinstance(lq, list):
        return []
    return lq


def split_markdown_sections(text: str) -> tuple[str, list[tuple[str, str]]]:
    """Preamble is everything before the first ## line; then (heading, body) pairs."""
    lines = text.splitlines()
    first_header: int | None = None
    for idx, line in enumerate(lines):
        if line.startswith("## "):
            first_header = idx
            break
    if first_header is None:
        return text.rstrip() + "\n", []

    preamble = "\n".join(lines[:first_header]).rstrip() + "\n"
    sections: list[tuple[str, str]] = []
    i = first_header
    while i < len(lines):
        line = lines[i]
        if line.startswith("## "):
            title = line[3:].strip()
            i += 1
            body_lines: list[str] = []
            while i < len(lines) and not lines[i].startswith("## "):
                body_lines.append(lines[i])
                i += 1
            body = "\n".join(body_lines).strip("\n")
            sections.append((title, body))
        else:
            i += 1
    return preamble, sections


def merge_output(
    preamble: str,
    level_blob: str,
    old_sections: list[tuple[str, str]],
    level_names: set[str],
) -> str:
    """Drop old sections whose heading matches a level folder; append the rest."""
    kept: list[tuple[str, str]] = []
    for title, body in old_sections:
        if title in level_names:
            continue
        kept.append((title, body))

    parts = [preamble.rstrip(), "", level_blob.rstrip()]
    for title, body in kept:
        parts.append("")
        parts.append(f"## {title}")
        if body.strip():
            parts.append("")
            parts.append(body)
    return "\n".join(parts).rstrip() + "\n"


def default_preamble() -> str:
    return "# Global questions (lines and answers)\n"


def main() -> int:
    root = repo_root()
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--levels-root",
        type=Path,
        default=root / "app/assets/quiz-data/levels",
        help="Directory containing level subfolders with questions.json",
    )
    ap.add_argument(
        "--output",
        type=Path,
        default=root / "cursor-claude-common/output/global-questions.md",
        help="Markdown file to write",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Print generated markdown to stdout only (no file write)",
    )
    args = ap.parse_args()

    levels = collect_levels(args.levels_root)
    if not levels:
        print("No levels found under", args.levels_root, file=sys.stderr)
        return 1

    level_names = {name for name, _ in levels}
    generated_chunks: list[str] = []
    for name, qpath in levels:
        try:
            qs = load_questions(qpath)
        except Exception as e:
            generated_chunks.append(f"## {name}\n\n_(failed to read {qpath}: {e})_\n")
            continue
        generated_chunks.append(render_table_for_level(name, qs))

    level_blob = "\n".join(generated_chunks).rstrip() + "\n"

    if args.dry_run:
        sys.stdout.write(default_preamble())
        sys.stdout.write("\n")
        sys.stdout.write(level_blob)
        return 0

    out_path: Path = args.output
    preamble = default_preamble()
    old_sections: list[tuple[str, str]] = []
    if out_path.is_file():
        old_text = out_path.read_text(encoding="utf-8")
        preamble, old_sections = split_markdown_sections(old_text)
        if not preamble.strip():
            preamble = default_preamble()

    merged = merge_output(preamble, level_blob, old_sections, level_names)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(merged, encoding="utf-8")
    print(f"Wrote {out_path} ({len(levels)} levels)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
