#!/usr/bin/env python3
"""
Mark lines or CSV rows where text matches level vocabulary from ``questions.json`` /
``translations.json`` (same extraction and matching as ``update_final_word_counts_from_levels.py``).

**Default action:** keep every line/row and wrap matched spans in ``*...*`` in the CSV
``word`` / ``Adverb`` column or in the full text line.

**``--remove``:** drop matching lines/rows instead (no ``*...*`` wrapping).

**Word source (pick one):**
  --word TEXT …     Manual targets; ``--match`` controls how they compare to each
                    line or CSV ``word`` cell.
  --words-from-levels
                    Build the vocabulary index from ``--levels-root`` the same way
                    as the update script, then treat a hit when ``match_csv_word``
                    would assign a non-zero level count (phrase or token hit).

**Format (``--format``):**
  auto  — ``.csv`` (case-insensitive) → CSV mode; anything else → line mode (default).
  csv   — Table with a ``word`` column (or ``Adverb``). All columns preserved on output.
  lines — Plain text: one logical line at a time (see implementation for newline handling).

Manual mode only — ``--match``:
  exact, substring, token.

Usage:
  python3 tools/mark_words_by_used_level_words.py -f oxford.txt --words-from-levels --dry-run
  python3 tools/mark_words_by_used_level_words.py -f words.csv -w hello
  python3 tools/mark_words_by_used_level_words.py -f list.txt --words-from-levels --remove --dry-run

``--mark`` is accepted as a no-op (marking is already the default).

Dry-run prints up to 20 affected entries, comma-separated on the same line as the summary.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

try:
    from update_final_word_counts_from_levels import (
        collect_word_to_levels,
        match_csv_word,
        repo_root,
    )
except ImportError:  # pragma: no cover
    collect_word_to_levels = None  # type: ignore[misc, assignment]
    match_csv_word = None  # type: ignore[misc, assignment]
    repo_root = None  # type: ignore[misc, assignment]

TOKEN_RE = re.compile(r"[a-z0-9]+(?:[-'][a-z0-9]+)*", re.IGNORECASE)


def normalize_phrase(text: str) -> str:
    return " ".join((text or "").strip().split()).lower()


def tokenize(text: str) -> list[str]:
    return [m.group(0).lower() for m in TOKEN_RE.finditer(text or "")]


def _normalize_headers(fieldnames: list[str] | None) -> dict[str, str]:
    """Map canonical key ``word`` to actual CSV header (word or Adverb)."""
    if not fieldnames:
        return {}
    lower_map = {f.lower(): f for f in fieldnames}
    out: dict[str, str] = {}
    for canon, aliases in (("word", ("word", "adverb")),):
        for a in aliases:
            if a in lower_map:
                out[canon] = lower_map[a]
                break
    return out


def row_matches_target(
    cell: str,
    target: str,
    match: str,
) -> bool:
    """True if this row's word cell should be removed for this target."""
    t = (target or "").strip()
    if not t:
        return False
    w = (cell or "").strip()
    if match == "exact":
        return normalize_phrase(w) == normalize_phrase(t)
    if match == "substring":
        return t.casefold() in w.casefold()
    if match == "token":
        if normalize_phrase(w) == normalize_phrase(t):
            return True
        wt, tt = set(tokenize(w)), set(tokenize(t))
        return bool(wt & tt)
    raise ValueError(f"unknown --match mode: {match}")


def row_should_remove(word_cell: str, targets: list[str], match: str) -> bool:
    return any(row_matches_target(word_cell, tgt, match) for tgt in targets)


def cell_should_remove(
    word_cell: str,
    *,
    targets: list[str] | None,
    match: str,
    word_levels: dict[str, set[str]] | None,
) -> bool:
    """True if manual targets match, or if ``match_csv_word`` hits level vocabulary."""
    if word_levels is not None:
        if match_csv_word is None:
            raise RuntimeError("update_final_word_counts_from_levels import failed")
        cnt, _levels = match_csv_word(word_cell, word_levels)
        return cnt > 0
    if not targets:
        return False
    return row_should_remove(word_cell, targets, match)


def mark_cell_levels(word_cell: str, word_levels: dict[str, set[str]]) -> str | None:
    """Return cell text with ``*...*`` around hits, or None if no level vocabulary hit."""
    if match_csv_word is None:
        raise RuntimeError("update_final_word_counts_from_levels import failed")
    if match_csv_word(word_cell, word_levels)[0] == 0:
        return None
    if normalize_phrase(word_cell) in word_levels:
        return f"*{word_cell}*"

    def repl(m: re.Match[str]) -> str:
        tok = m.group(0)
        if tok.lower() in word_levels:
            return f"*{tok}*"
        return tok

    return TOKEN_RE.sub(repl, word_cell)


def mark_cell_manual(word_cell: str, targets: list[str], match: str) -> str | None:
    """Return cell text with ``*...*`` around hits for manual ``--word`` mode."""
    if not row_should_remove(word_cell, targets, match):
        return None
    if match == "exact":
        return f"*{word_cell}*"
    if match == "substring":
        out = word_cell
        for t in targets:
            needle = str(t).strip()
            if not needle or needle.casefold() not in out.casefold():
                continue
            pat = re.compile(re.escape(needle), re.IGNORECASE)
            out = pat.sub(lambda m: f"*{m.group(0)}*", out)
        return out
    # token
    tt_set: set[str] = set()
    for t in targets:
        tt_set |= set(tokenize(str(t)))

    def repl(m: re.Match[str]) -> str:
        if m.group(0).lower() in tt_set:
            return f"*{m.group(0)}*"
        return m.group(0)

    return TOKEN_RE.sub(repl, word_cell)


def apply_mark_to_cell(
    word_cell: str,
    *,
    targets: list[str] | None,
    match: str,
    word_levels: dict[str, set[str]] | None,
) -> str | None:
    if word_levels is not None:
        return mark_cell_levels(word_cell, word_levels)
    if targets:
        return mark_cell_manual(word_cell, targets, match)
    return None


DRY_RUN_PREVIEW_MAX = 20


def _preview_label(text: str) -> str:
    """Single-line safe fragment for dry-run comma list."""
    return (text or "").replace("\r", "").replace("\n", " ").strip()


def print_dry_run_removed_sample(removed_labels: list[str]) -> str:
    """Comma-separated first N items for one-line dry-run suffix; empty if none."""
    if not removed_labels:
        return ""
    frag = [_preview_label(s) for s in removed_labels[:DRY_RUN_PREVIEW_MAX]]
    frag = [s for s in frag if s]
    if not frag:
        return ""
    return ", ".join(frag)


def effective_format(path: Path, format_arg: str) -> str:
    if format_arg in ("csv", "lines"):
        return format_arg
    if format_arg != "auto":
        raise ValueError(f"unknown format: {format_arg}")
    return "csv" if path.suffix.lower() == ".csv" else "lines"


def filter_lines(
    path: Path,
    out_path: Path,
    dry_run: bool,
    *,
    mark: bool,
    targets: list[str] | None,
    match: str,
    word_levels: dict[str, set[str]] | None,
) -> tuple[int, int, int]:
    """
    Returns (kept_line_count, removed_count, marked_count).
    ``removed_count`` is 0 when ``mark``; ``marked_count`` is 0 when not ``mark``.
    """
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"error: cannot read {path}: {e}", file=sys.stderr)
        raise SystemExit(1)
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")

    lines_out: list[str] = []
    removed = 0
    marked = 0
    preview: list[str] = []
    for line in text.splitlines():
        core = line.strip("\r\n")
        hit = cell_should_remove(
            core, targets=targets, match=match, word_levels=word_levels
        )
        if not hit:
            lines_out.append(core)
            continue
        if mark:
            new_core = apply_mark_to_cell(
                core, targets=targets, match=match, word_levels=word_levels
            )
            if new_core is None:
                new_core = core
            lines_out.append(new_core)
            marked += 1
            if len(preview) < DRY_RUN_PREVIEW_MAX:
                preview.append(new_core)
        else:
            removed += 1
            if len(preview) < DRY_RUN_PREVIEW_MAX:
                preview.append(core)

    kept = len(lines_out)
    mode = "levels-vocab" if word_levels is not None else f"match={match}"
    if dry_run:
        if mark:
            msg = (
                f"[dry-run] {path} (lines): would mark {marked} line(s), "
                f"keep all {kept} ({mode})"
            )
        else:
            msg = (
                f"[dry-run] {path} (lines): would remove {removed} line(s), "
                f"keep {kept} ({mode})"
            )
        sample = print_dry_run_removed_sample(preview)
        if sample:
            msg += "  " + sample
        print(msg)
        return kept, removed, marked

    out_path.parent.mkdir(parents=True, exist_ok=True)
    body = "\n".join(lines_out)
    if body:
        body += "\n"
    out_path.write_text(body, encoding="utf-8")
    if mark:
        print(
            f"Wrote {out_path} (lines): marked {marked} line(s), "
            f"wrote {kept} total ({mode})"
        )
    else:
        print(
            f"Wrote {out_path} (lines): removed {removed} line(s), kept {kept} ({mode})"
        )
    return kept, removed, marked


def filter_csv(
    path: Path,
    out_path: Path,
    dry_run: bool,
    *,
    mark: bool,
    targets: list[str] | None,
    match: str,
    word_levels: dict[str, set[str]] | None,
) -> tuple[int, int, int]:
    """
    Returns (row_count_written, removed_count, marked_count).
    """
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"error: cannot read {path}: {e}", file=sys.stderr)
        raise SystemExit(1)
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")

    reader = csv.DictReader(text.splitlines())
    hdr_map = _normalize_headers(reader.fieldnames)
    if "word" not in hdr_map:
        print(
            "error: CSV must have a `word` column (or `Adverb`).",
            file=sys.stderr,
        )
        raise SystemExit(1)
    wkey = hdr_map["word"]
    fieldnames = list(reader.fieldnames or [])

    rows_out: list[dict[str, str]] = []
    removed = 0
    marked = 0
    preview: list[str] = []
    for row in reader:
        if not row:
            continue
        word_cell = row.get(wkey) or ""
        hit = cell_should_remove(
            word_cell, targets=targets, match=match, word_levels=word_levels
        )
        if not hit:
            rows_out.append({k: row.get(k, "") for k in fieldnames})
            continue
        if mark:
            new_word = apply_mark_to_cell(
                word_cell, targets=targets, match=match, word_levels=word_levels
            )
            if new_word is None:
                new_word = word_cell
            new_row = {k: row.get(k, "") for k in fieldnames}
            new_row[wkey] = new_word
            rows_out.append(new_row)
            marked += 1
            if len(preview) < DRY_RUN_PREVIEW_MAX:
                preview.append(new_word)
        else:
            removed += 1
            if len(preview) < DRY_RUN_PREVIEW_MAX:
                preview.append(word_cell)

    kept = len(rows_out)
    mode = "levels-vocab" if word_levels is not None else f"match={match}"
    if dry_run:
        if mark:
            msg = (
                f"[dry-run] {path}: would mark {marked} row(s) "
                f"in `{wkey}` column, {kept} rows total ({mode})"
            )
        else:
            msg = f"[dry-run] {path}: would remove {removed} row(s), keep {kept} ({mode})"
        sample = print_dry_run_removed_sample(preview)
        if sample:
            msg += "  " + sample
        print(msg)
        return kept, removed, marked

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows_out)
    if mark:
        print(
            f"Wrote {out_path}: marked {marked} row(s) in `{wkey}` column, "
            f"{kept} rows total ({mode})"
        )
    else:
        print(f"Wrote {out_path}: removed {removed} row(s), kept {kept} ({mode})")
    return kept, removed, marked


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--file",
        "-f",
        type=Path,
        required=True,
        help="Input file (.csv or plain text, etc.)",
    )
    parser.add_argument(
        "--format",
        choices=("auto", "csv", "lines"),
        default="auto",
        help="auto: .csv → CSV mode; else match whole lines (default: auto)",
    )
    parser.add_argument(
        "--word",
        "-w",
        action="append",
        dest="words",
        metavar="TEXT",
        default=None,
        help="Word or phrase to match (repeat for multiple targets); not used with --words-from-levels",
    )
    parser.add_argument(
        "--words-from-levels",
        action="store_true",
        help="Match vocabulary from questions.json + translations.json under --levels-root "
        "(same rules as update_final_word_counts_from_levels.py)",
    )
    parser.add_argument(
        "--levels-root",
        type=Path,
        default=None,
        help="Root folder containing level subfolders (default: app/assets/quiz-data/levels under repo root)",
    )
    parser.add_argument(
        "--match",
        choices=("exact", "substring", "token"),
        default="exact",
        help="Manual --word mode only: how each line or word column compares (ignored with --words-from-levels)",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=None,
        help="Output path (default: overwrite --file)",
    )
    parser.add_argument(
        "--remove",
        action="store_true",
        help="Delete matching lines/rows instead of marking with *...* (default is to mark)",
    )
    parser.add_argument(
        "--mark",
        action="store_true",
        help=argparse.SUPPRESS,
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print how many rows/lines would be removed or marked; do not write",
    )
    args = parser.parse_args()

    if args.remove and args.mark:
        print("error: do not pass both --remove and --mark", file=sys.stderr)
        return 1

    mark_mode = not args.remove

    if collect_word_to_levels is None or repo_root is None:
        print(
            "error: could not import update_final_word_counts_from_levels (run from repo as "
            "python3 tools/mark_words_by_used_level_words.py …)",
            file=sys.stderr,
        )
        return 1

    in_path = args.file.resolve()
    if not in_path.is_file():
        print(f"error: not a file: {in_path}", file=sys.stderr)
        return 1

    use_levels = bool(args.words_from_levels)
    targets = [w for w in (args.words or []) if str(w).strip()]
    if use_levels and targets:
        print("error: use either --words-from-levels or --word, not both", file=sys.stderr)
        return 1
    if not use_levels and not targets:
        print(
            "error: pass --words-from-levels or at least one --word",
            file=sys.stderr,
        )
        return 1

    word_levels: dict[str, set[str]] | None = None
    if use_levels:
        levels_root = (
            args.levels_root.resolve()
            if args.levels_root is not None
            else (repo_root() / "app/assets/quiz-data/levels").resolve()
        )
        if not levels_root.is_dir():
            print(f"error: not a directory: {levels_root}", file=sys.stderr)
            return 1
        word_levels = collect_word_to_levels(levels_root)
        print(
            f"Indexed level vocabulary from {levels_root} ({len(word_levels)} distinct tokens/phrases).",
            file=sys.stderr,
        )

    out_path = (args.output or args.file).resolve()

    fmt = effective_format(in_path, args.format)
    kw = dict(
        mark=mark_mode,
        targets=None if word_levels is not None else targets,
        match=args.match,
        word_levels=word_levels,
    )
    if fmt == "csv":
        filter_csv(in_path, out_path, args.dry_run, **kw)
    else:
        filter_lines(in_path, out_path, args.dry_run, **kw)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
