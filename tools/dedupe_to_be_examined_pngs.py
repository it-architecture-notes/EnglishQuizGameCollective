#!/usr/bin/env python3
"""
Remove PNGs under `app/assets/quiz-data/levels/to-be-examined/` that already exist
elsewhere under the same ``levels`` root, then delete `to-be-examined` subfolders
that contain no image files.

**Duplicate corpus (default):** every immediate subdirectory of ``levels-root``
except ``to-be-examined`` — e.g. ``implemented/``, ``kitchen/``, ``at-the-mall/``,
etc. A PNG under ``to-be-examined`` is removed if it matches that corpus.

Use ``--corpus-peer NAME`` (repeatable) to scan only specific peers, e.g.
``--corpus-peer implemented`` for the old single-folder behavior.

With ``--unique-basename-within-tbe``, only dedupe *within* ``to-be-examined``:
each ``*.png`` basename may appear once; keep the lexicographically first full path
and delete the others (ignores the corpus).

Match modes (corpus vs ``to-be-examined``):
  - relpath: same path relative to each top-level peer, e.g. ``some-level/icon.png``
    exists under some peer and under ``to-be-examined``.
  - basename: same filename anywhere in the corpus (default).
  - bytes: identical file bytes (SHA-256) as some corpus PNG.

After deletions, any directory under `to-be-examined` whose subtree has no image
files (.png, .jpg, .jpeg, .webp, .gif) is removed entirely (including non-images).

Usage:
  python3 tools/dedupe_to_be_examined_pngs.py --dry-run
  python3 tools/dedupe_to_be_examined_pngs.py
  python3 tools/dedupe_to_be_examined_pngs.py --match relpath --dry-run
  python3 tools/dedupe_to_be_examined_pngs.py --corpus-peer implemented --dry-run
  python3 tools/dedupe_to_be_examined_pngs.py --unique-basename-within-tbe --dry-run
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from collections import defaultdict
from pathlib import Path

IMAGE_EXTS = frozenset({".png", ".jpg", ".jpeg", ".webp", ".gif"})


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def corpus_peer_dirs(
    levels_root: Path,
    tbe_name: str,
    corpus_peers: list[str] | None,
) -> list[Path]:
    """
    Directories under ``levels_root`` whose PNGs form the duplicate corpus
    (everything except ``to-be-examined`` by default).
    """
    if corpus_peers:
        roots: list[Path] = []
        for name in corpus_peers:
            p = levels_root / name
            if p.is_dir():
                roots.append(p)
            else:
                print(f"warn: corpus-peer not a directory, skipping: {p}", file=sys.stderr)
        return roots

    roots = []
    for p in sorted(levels_root.iterdir()):
        if not p.is_dir():
            continue
        if p.name == tbe_name:
            continue
        roots.append(p)
    return roots


def collect_corpus_pngs(corpus_roots: list[Path]) -> tuple[set[str], set[str], set[str]]:
    """
    Scan all ``*.png`` under each corpus root (paths relative to that root).

    Returns:
      rel_paths: union of relative POSIX paths (per-root relpath strings)
      basenames: union of filenames
      content_hashes: SHA-256 hex digests of every corpus PNG
    """
    rel_paths: set[str] = set()
    basenames: set[str] = set()
    content_hashes: set[str] = set()

    for root in corpus_roots:
        for p in root.rglob("*.png"):
            if not p.is_file():
                continue
            rel = p.relative_to(root).as_posix()
            rel_paths.add(rel)
            basenames.add(p.name)
            content_hashes.add(hashlib.sha256(p.read_bytes()).hexdigest())

    return rel_paths, basenames, content_hashes


def should_remove_tbe_png(
    path: Path,
    tbe_dir: Path,
    match: str,
    corpus_rel_paths: set[str],
    corpus_basenames: set[str],
    corpus_sha_set: set[str],
) -> bool:
    rel = path.relative_to(tbe_dir).as_posix()
    if match == "relpath":
        return rel in corpus_rel_paths
    if match == "basename":
        return path.name in corpus_basenames
    if match == "bytes":
        h = hashlib.sha256(path.read_bytes()).hexdigest()
        return h in corpus_sha_set
    raise ValueError(f"unknown match mode: {match}")


def subtree_has_image_files(
    directory: Path, ignore_paths: frozenset[Path] | None = None
) -> bool:
    ignore = ignore_paths or frozenset()
    for child in directory.rglob("*"):
        if not child.is_file():
            continue
        if child in ignore:
            continue
        if child.suffix.lower() in IMAGE_EXTS:
            return True
    return False


def prune_empty_image_dirs(
    tbe_dir: Path,
    dry_run: bool,
    ignore_image_paths: frozenset[Path] | None = None,
) -> list[str]:
    """
    Remove every subdirectory under tbe_dir that has no image files in its subtree.

    When ``ignore_image_paths`` is set (e.g. PNGs slated for deletion in a dry-run),
    those files are ignored so pruning matches the post-delete state.
    """
    removed: list[str] = []
    all_dirs = sorted(
        (p for p in tbe_dir.rglob("*") if p.is_dir()),
        key=lambda p: len(p.parts),
        reverse=True,
    )
    for d in all_dirs:
        if d == tbe_dir:
            continue
        if subtree_has_image_files(d, ignore_image_paths):
            continue
        rel = d.relative_to(tbe_dir).as_posix()
        if dry_run:
            removed.append(rel)
            continue
        shutil.rmtree(d, ignore_errors=True)
        removed.append(rel)
    return removed


def collect_tbe_basename_duplicates(tbe_dir: Path) -> list[Path]:
    """
    For each PNG basename under ``tbe_dir``, keep one file (lexicographically
    smallest path) and return the list of other paths to delete.
    """
    by_name: dict[str, list[Path]] = defaultdict(list)
    for p in tbe_dir.rglob("*.png"):
        if p.is_file():
            by_name[p.name].append(p)

    to_delete: list[Path] = []
    for _name, paths in by_name.items():
        if len(paths) <= 1:
            continue
        paths_sorted = sorted(paths, key=lambda x: x.as_posix())
        to_delete.extend(paths_sorted[1:])
    return sorted(to_delete, key=lambda x: x.as_posix())


def main() -> int:
    root = repo_root()
    default_levels = root / "app" / "assets" / "quiz-data" / "levels"

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--levels-root",
        type=Path,
        default=default_levels,
        help=f"Parent of level folders (implemented/, to-be-examined/, …) (default: {default_levels})",
    )
    parser.add_argument(
        "--corpus-peer",
        action="append",
        dest="corpus_peers",
        metavar="NAME",
        help="Only scan PNGs under levels-root/NAME as the duplicate corpus (repeatable). "
        "Default: every other immediate subdirectory of levels-root except to-be-examined.",
    )
    parser.add_argument(
        "--to-be-examined",
        type=str,
        default="to-be-examined",
        dest="tbe",
        help="Folder name under levels-root (default: to-be-examined)",
    )
    parser.add_argument(
        "--match",
        choices=("relpath", "basename", "bytes"),
        default="basename",
        help="How to treat a PNG under to-be-examined as a duplicate (default: basename)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions without deleting files or directories",
    )
    parser.add_argument(
        "--no-prune",
        action="store_true",
        help="Do not remove to-be-examined subfolders with no image files",
    )
    parser.add_argument(
        "--unique-basename-within-tbe",
        action="store_true",
        help="Within to-be-examined only: one PNG per basename; keep lexicographically first path",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Print corpus peer names and index sizes on stderr",
    )
    args = parser.parse_args()

    levels_root: Path = args.levels_root.resolve()
    tbe_dir = levels_root / args.tbe

    if not tbe_dir.is_dir():
        print(f"error: to-be-examined dir not found: {tbe_dir}", file=sys.stderr)
        return 1

    if args.unique_basename_within_tbe:
        to_delete = collect_tbe_basename_duplicates(tbe_dir)
    else:
        corpus_roots = corpus_peer_dirs(levels_root, args.tbe, args.corpus_peers)
        if not corpus_roots:
            print(
                "error: no corpus directories to scan (check --levels-root, --corpus-peer, --to-be-examined)",
                file=sys.stderr,
            )
            return 1

        corpus_rel_paths, corpus_basenames, corpus_sha_set = collect_corpus_pngs(corpus_roots)
        if args.verbose:
            peer_label = ", ".join(p.name for p in corpus_roots)
            print(f"corpus: {len(corpus_roots)} peer(s) — {peer_label}", file=sys.stderr)
            print(
                f"corpus stats: rel_paths={len(corpus_rel_paths)}, "
                f"distinct_basenames={len(corpus_basenames)}, "
                f"distinct_sha256={len(corpus_sha_set)}",
                file=sys.stderr,
            )

        to_delete = []
        for p in sorted(tbe_dir.rglob("*.png")):
            if not p.is_file():
                continue
            try:
                if should_remove_tbe_png(
                    p,
                    tbe_dir,
                    args.match,
                    corpus_rel_paths,
                    corpus_basenames,
                    corpus_sha_set,
                ):
                    to_delete.append(p)
            except OSError as e:
                print(f"warn: skip {p}: {e}", file=sys.stderr)

    ignore_for_prune: frozenset[Path] | None = (
        frozenset(to_delete) if args.dry_run and to_delete else None
    )

    op_note = (
        "unique-basename-within-tbe"
        if args.unique_basename_within_tbe
        else f"match={args.match}"
    )
    for p in to_delete:
        rel = p.relative_to(tbe_dir).as_posix()
        if args.dry_run:
            print(f"would delete png: {rel}  ({op_note})")
        else:
            p.unlink(missing_ok=True)
            print(f"deleted png: {rel}  ({op_note})")

    pruned: list[str] = []
    if not args.no_prune:
        pruned = prune_empty_image_dirs(
            tbe_dir, args.dry_run, ignore_image_paths=ignore_for_prune
        )
        label = "would remove dir (no images):" if args.dry_run else "removed dir (no images):"
        for rel in sorted(pruned):
            print(f"{label} {rel}")

    print(
        f"summary: pngs {'to delete' if args.dry_run else 'deleted'}={len(to_delete)}, "
        f"dirs {'to remove' if args.dry_run else 'removed'}={len(pruned)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
