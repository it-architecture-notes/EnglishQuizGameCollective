#!/usr/bin/env python3
"""
Prune tabbed filler lines from the Oxford 3000 word list between two given rows.

You pass the full row text for the start and end boundaries (with or without a leading
``**``, and without shell quotes), e.g.:

  python3 tools/prune_oxford_wordlist_star_gaps.py --start cook v. A1 --end fill v. A1

The script:

  1. Finds those two lines (ignores leading tabs, optional ``**``, outer whitespace).
  2. Considers every line strictly between them (the "gap").
  3. Removes each gap line that is tab-indented and does *not* start with ``!``
     after the tabs.
  4. Keeps boundary rows, ``**`` rows inside the gap, and tabbed ``!`` rows.
  5. Strips the leading ``!`` from every remaining line in the file that still
     has one.

Usage:
  python3 tools/prune_oxford_wordlist_star_gaps.py --start cook v. A1 --end fill v. A1 --dry-run

  python3 tools/prune_oxford_wordlist_star_gaps.py --start "**dirty adj. A1" --end "**fine adj. A1"

  python3 tools/prune_oxford_wordlist_star_gaps.py --start dirty adj. A1 --end fine adj. A1 -o cleaned.txt --verbose
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


_STAR_MARK = "**"
_BOUNDARY_FLAGS = frozenset({"--start", "--end", "--oxford", "--output", "-o"})


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def normalize_row_content(text: str) -> str:
    """Row text for boundary matching: no tabs, optional ``**``, collapsed spaces."""
    s = (text or "").strip().lstrip("\t")
    if s.startswith(_STAR_MARK):
        s = s[len(_STAR_MARK) :].lstrip()
    return " ".join(s.split())


def normalize_boundary(text: str) -> str:
    return normalize_row_content(text)


def line_matches_boundary(line: str, boundary: str) -> bool:
    return normalize_row_content(line) == normalize_boundary(boundary)


def _flag_name(arg: str) -> str | None:
    if not arg.startswith("-"):
        return None
    return arg.split("=", 1)[0]


def _collect_boundary_value(argv: list[str], i: int, stop_at: str) -> tuple[str, int]:
    """Read boundary words from argv[i] until stop_at or another known flag."""
    parts: list[str] = []
    while i < len(argv):
        arg = argv[i]
        if arg == stop_at:
            break
        name = _flag_name(arg)
        if name in _BOUNDARY_FLAGS or name in ("--dry-run", "--verbose", "--help", "-h"):
            break
        parts.append(arg)
        i += 1
    return " ".join(parts), i


def parse_cli(argv: list[str], default_oxford: Path) -> argparse.Namespace:
    start: str | None = None
    end: str | None = None
    oxford = default_oxford
    output: Path | None = None
    dry_run = False
    verbose = False

    i = 1
    while i < len(argv):
        arg = argv[i]
        if arg in ("-h", "--help"):
            return argparse.Namespace(help=True)
        if arg == "--start":
            i += 1
            start, i = _collect_boundary_value(argv, i, "--end")
            continue
        if arg.startswith("--start="):
            start = arg.split("=", 1)[1]
            i += 1
            continue
        if arg == "--end":
            i += 1
            end, i = _collect_boundary_value(argv, i, stop_at="")
            continue
        if arg.startswith("--end="):
            end = arg.split("=", 1)[1]
            i += 1
            continue
        if arg == "--oxford":
            i += 1
            oxford = Path(argv[i])
            i += 1
            continue
        if arg.startswith("--oxford="):
            oxford = Path(arg.split("=", 1)[1])
            i += 1
            continue
        if arg in ("-o", "--output"):
            i += 1
            output = Path(argv[i])
            i += 1
            continue
        if arg.startswith("--output="):
            output = Path(arg.split("=", 1)[1])
            i += 1
            continue
        if arg == "--dry-run":
            dry_run = True
            i += 1
            continue
        if arg == "--verbose":
            verbose = True
            i += 1
            continue
        raise SystemExit(f"error: unrecognized argument: {arg}")

    if not start or not end:
        raise SystemExit("error: both --start and --end are required")

    return argparse.Namespace(
        start=start,
        end=end,
        oxford=oxford,
        output=output,
        dry_run=dry_run,
        verbose=verbose,
        help=False,
    )


def find_boundary_index(lines: list[str], boundary: str, label: str) -> int:
    target = normalize_boundary(boundary)
    if not target:
        print(f"error: empty {label} boundary", file=sys.stderr)
        raise ValueError(f"empty {label}")

    matches = [i for i, ln in enumerate(lines) if line_matches_boundary(ln, boundary)]
    if len(matches) == 1:
        return matches[0]
    if not matches:
        print(f"error: {label} boundary not found: {target!r}", file=sys.stderr)
        raise ValueError(f"{label} not found")
    print(
        f"error: {label} boundary matched {len(matches)} lines: {target!r}",
        file=sys.stderr,
    )
    raise ValueError(f"ambiguous {label}")


def is_tabbed_line(line: str) -> bool:
    return bool(line) and line[0] == "\t"


def has_bang_marker(line: str) -> bool:
    """Tabbed (or other) line with ``!`` immediately after leading tabs."""
    return line.lstrip("\t").startswith("!")


def indices_to_remove_in_gap(lines: list[str], start_idx: int, end_idx: int) -> set[int]:
    """Drop tab-indented gap lines that do not start with ``!``."""
    remove: set[int] = set()
    for i in range(start_idx + 1, end_idx):
        ln = lines[i]
        if is_tabbed_line(ln) and not has_bang_marker(ln):
            remove.add(i)
    return remove


def strip_bang_prefix(line: str) -> tuple[str, bool]:
    """Remove a single leading ``!`` after optional tab indent. Returns (line, changed)."""
    i = 0
    while i < len(line) and line[i] == "\t":
        i += 1
    if i < len(line) and line[i] == "!":
        return line[:i] + line[i + 1 :], True
    return line, False


def strip_all_bang_prefixes(lines: list[str]) -> tuple[list[str], int]:
    out: list[str] = []
    n = 0
    for line in lines:
        stripped, changed = strip_bang_prefix(line)
        out.append(stripped)
        if changed:
            n += 1
    return out, n


def prune_lines(
    lines: list[str], start_boundary: str, end_boundary: str
) -> tuple[list[str], set[int], int, int]:
    start_idx = find_boundary_index(lines, start_boundary, "start")
    end_idx = find_boundary_index(lines, end_boundary, "end")
    if start_idx >= end_idx:
        print(
            f"error: start boundary (line {start_idx + 1}) must come before "
            f"end boundary (line {end_idx + 1})",
            file=sys.stderr,
        )
        raise ValueError("start after end")

    remove = indices_to_remove_in_gap(lines, start_idx, end_idx)
    kept = [ln for i, ln in enumerate(lines) if i not in remove]
    kept, bang_stripped = strip_all_bang_prefixes(kept)
    return kept, remove, end_idx - start_idx - 1, bang_stripped


def main() -> int:
    root = repo_root()
    default_oxford = (
        root
        / "cursor-claude-common/references/remove-word-list-references/3000 words oxford.txt"
    )

    if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0

    try:
        args = parse_cli(sys.argv, default_oxford)
    except SystemExit as e:
        print(e, file=sys.stderr)
        return 2

    oxford = args.oxford.resolve()
    out_path = (args.output or args.oxford).resolve()

    if not oxford.is_file():
        print(f"error: not a file: {oxford}", file=sys.stderr)
        return 1

    text = oxford.read_text(encoding="utf-8")
    if text.startswith("\ufeff"):
        text = text.lstrip("\ufeff")
    lines = text.splitlines()

    try:
        kept, remove, gap_size, bang_stripped = prune_lines(lines, args.start, args.end)
    except ValueError:
        return 1

    if args.verbose and remove:
        print("Removed lines:")
        for i in sorted(remove):
            print(f"  {lines[i].strip()[:100]}")

    summary = (
        f"gap lines={gap_size}, removed={len(remove)}, ! stripped={bang_stripped}, "
        f"kept={len(kept)} (from {len(lines)} lines)"
    )

    if args.dry_run:
        print(f"[dry-run] {oxford}: {summary}")
        return 0

    body = "\n".join(kept)
    if body:
        body += "\n"
    out_path.write_text(body, encoding="utf-8")
    print(f"Wrote {out_path}: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
