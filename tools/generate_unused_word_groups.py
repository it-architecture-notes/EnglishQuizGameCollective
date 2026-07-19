#!/usr/bin/env python3
"""
Build frequency-ordered groups of unused reference vocabulary for common-words planning.

Each group: 15 core words (9 verbs ~60% + 6 adj/adv/prep/aux/conj) + 4 WordPairs
(adj, adv, or noun). Phrasal verbs count separately from their base verb when unused.
"""

from __future__ import annotations

import csv
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REF_DIR = ROOT / "cursor-claude-common/references/final words"
OUTPUT = ROOT / "cursor-claude-common/output/unused-words-groups.txt"

CEFR_ORDER = {"A1": 0, "A2": 1, "B1": 2, "B2": 3, "C1": 4, "C2": 5, "": 9}

FILES: list[tuple[str, str]] = [
    ("verb", "verbs-400.csv"),
    ("common_verb", "common-verbs.csv"),
    ("adj", "adjectives-300.csv"),
    ("adv", "adverbs-150.csv"),
    ("noun", "langeek-500-most-common-nouns.csv"),
    ("prep", "prepositions.csv"),
    ("aux", "auxiliaries.csv"),
    ("conj", "conjunctions.csv"),
]

# When a word appears in multiple files, keep the highest-priority bucket.
KIND_PRIORITY = {
    "common_verb": 0,
    "verb": 1,
    "adj": 2,
    "adv": 3,
    "noun": 4,
    "prep": 5,
    "aux": 6,
    "conj": 7,
}

OTHER15_KINDS = frozenset({"adj", "adv", "prep", "aux", "conj"})
EXTRA4_KINDS = frozenset({"adj", "adv", "noun"})
VERB_KINDS = frozenset({"verb", "common_verb"})


@dataclass
class Word:
    word: str
    kind: str
    cefr: str
    rank: int
    source: str

    @property
    def key(self) -> str:
        return self.word.lower()

    def display(self) -> str:
        if self.kind in VERB_KINDS:
            w = self.word.strip()
            if w.lower().startswith("to "):
                return w
            return f"to {w}"
        return self.word


def load_words() -> list[Word]:
    rows: list[Word] = []
    for kind, filename in FILES:
        path = REF_DIR / filename
        with path.open(encoding="utf-8") as f:
            for rank, row in enumerate(csv.DictReader(f), start=1):
                word = (row.get("word") or "").strip()
                if not word:
                    continue
                count = int((row.get("count") or "0").strip() or 0)
                if count != 0:
                    continue
                rows.append(
                    Word(
                        word=word,
                        kind=kind,
                        cefr=(row.get("level") or "").strip(),
                        rank=rank,
                        source=filename,
                    )
                )
    return rows


def dedupe_unused(rows: list[Word]) -> list[Word]:
    best: dict[str, Word] = {}
    for row in rows:
        prev = best.get(row.key)
        if prev is None or KIND_PRIORITY[row.kind] < KIND_PRIORITY[prev.kind]:
            best[row.key] = row
    return list(best.values())


def effective_cefr(w: Word) -> str:
    if w.cefr:
        return w.cefr
    # Frequency lists without CEFR labels are treated as core A1 vocabulary.
    if w.kind in {"common_verb", "noun"}:
        return "A1"
    return ""


def verb_sort_key(w: Word) -> tuple:
    is_phrasal = " " in w.word
    if w.kind == "common_verb":
        tier = 0
    elif not is_phrasal:
        tier = 1
    else:
        tier = 2
    return (CEFR_ORDER.get(effective_cefr(w), 9), tier, w.rank, w.word.lower())


def other15_sort_key(w: Word) -> tuple:
    kind_bias = {"adj": 0, "adv": 1, "prep": 2, "aux": 3, "conj": 4}.get(w.kind, 5)
    return (CEFR_ORDER.get(effective_cefr(w), 9), kind_bias, w.rank, w.word.lower())


def extra4_sort_key(w: Word) -> tuple:
    kind_bias = {"adj": 0, "adv": 1, "noun": 2}.get(w.kind, 3)
    return (CEFR_ORDER.get(effective_cefr(w), 9), kind_bias, w.rank, w.word.lower())


def take(pool: list[Word], used: set[str], n: int) -> list[Word]:
    picked: list[Word] = []
    remaining: list[Word] = []
    for w in pool:
        if w.key in used:
            continue
        if len(picked) < n:
            picked.append(w)
            used.add(w.key)
        else:
            remaining.append(w)
    pool[:] = remaining
    return picked


def take_other15(
    adj_adv: list[Word],
    function: list[Word],
    used: set[str],
    n: int,
) -> list[Word]:
    """Prefer adjectives/adverbs; fall back to prep/aux/conj only when needed."""
    picked = take(adj_adv, used, n)
    if len(picked) < n:
        picked.extend(take(function, used, n - len(picked)))
    return picked


def remaining_total(*pools: list[Word]) -> int:
    return sum(len(p) for p in pools)


def build_flexible_groups(
    remainder: list[Word],
    start_index: int,
) -> tuple[list[dict[str, list[Word]]], list[Word]]:
    """Pack leftover vocabulary into 19-word groups when strict POS quotas are exhausted."""
    groups: list[dict[str, list[Word]]] = []
    pool = sorted(
        remainder,
        key=lambda w: (
            CEFR_ORDER.get(effective_cefr(w), 9),
            KIND_PRIORITY.get(w.kind, 9),
            w.rank,
            w.word.lower(),
        ),
    )
    idx = start_index
    while len(pool) >= 19:
        chunk = pool[:19]
        pool = pool[19:]
        idx += 1
        groups.append(
            {
                "verbs": [w for w in chunk if w.kind in VERB_KINDS],
                "other": [w for w in chunk if w.kind in OTHER15_KINDS],
                "extra": [w for w in chunk if w.kind in EXTRA4_KINDS],
                "flexible": True,
            }
        )
    return groups, pool


def build_groups(unused: list[Word]) -> list[dict[str, list[Word]]]:
    verbs = sorted([w for w in unused if w.kind in VERB_KINDS], key=verb_sort_key)
    adj_adv = sorted(
        [w for w in unused if w.kind in {"adj", "adv"}],
        key=other15_sort_key,
    )
    function = sorted(
        [w for w in unused if w.kind in {"prep", "aux", "conj"}],
        key=other15_sort_key,
    )
    extra4 = sorted([w for w in unused if w.kind in EXTRA4_KINDS], key=extra4_sort_key)

    used: set[str] = set()
    groups: list[dict[str, list[Word]]] = []

    while len(verbs) >= 9 and (len(adj_adv) + len(function)) >= 6 and len(extra4) >= 4:
        g_verbs = take(verbs, used, 9)
        g_other = take_other15(adj_adv, function, used, 6)
        g_extra = take(extra4, used, 4)
        groups.append({"verbs": g_verbs, "other": g_other, "extra": g_extra})

    remainder: list[Word] = []
    for pool in (verbs, adj_adv, function, extra4):
        for w in pool:
            if w.key not in used:
                remainder.append(w)
                used.add(w.key)

    flex_groups, tail = build_flexible_groups(remainder, len(groups))
    groups.extend(flex_groups)
    if tail:
        groups.append(
            {
                "verbs": [w for w in tail if w.kind in VERB_KINDS],
                "other": [w for w in tail if w.kind in OTHER15_KINDS],
                "extra": [w for w in tail if w.kind in EXTRA4_KINDS],
                "flexible": True,
            }
        )
    return groups


def format_groups(groups: list[dict[str, list[Word]]], total_unused: int) -> str:
    lines: list[str] = [
        "Unused reference vocabulary — grouped for common-words planning",
        "=" * 72,
        "",
        "Rules:",
        "  • 15 core words per group: 9 verbs (~60%) + 6 adj/adv/prep/aux/conj",
        "  • 4 WordPairs words: adjective, adverb, or noun",
        "  • Phrasal verbs are separate from base verbs (e.g. to look for ≠ to look)",
        "  • Each word appears in at most one group",
        "  • Groups 1–33: strict 9 verbs + 6 adj/adv/function words + 4 adj/adv/noun",
        "  • Groups 34+: flexible 19-word packs (mostly remaining nouns; verb pool exhausted)",
        "",
        f"Total unused words (deduped): {total_unused}",
        f"Groups: {len(groups)}",
        "",
    ]

    for i, group in enumerate(groups, start=1):
        verbs = group["verbs"]
        other = group["other"]
        extra = group["extra"]
        total = len(verbs) + len(other) + len(extra)
        label = f"--- Group {i} ({total} words) ---"
        if total < 19:
            label = f"--- Group {i} ({total} words, partial) ---"
        elif group.get("flexible"):
            label = f"--- Group {i} ({total} words, flexible mix) ---"
        lines.append(label)
        if group.get("flexible"):
            all_words = verbs + other + extra
            lines.append(f"All ({len(all_words)}): {', '.join(w.display() for w in all_words) or '—'}")
            lines.append(
                "(Flexible group: strict 9+6+4 quotas relaxed after core verb/adj pools were used up.)"
            )
        else:
            lines.append(f"Verbs (9 target, {len(verbs)}): {', '.join(w.display() for w in verbs) or '—'}")
            lines.append(
                f"Other (6 target, {len(other)}): {', '.join(w.display() for w in other) or '—'}"
            )
            lines.append(
                f"WordPairs (4 target, {len(extra)}): {', '.join(w.display() for w in extra) or '—'}"
            )
        lines.append("")

    assigned = sum(len(g["verbs"]) + len(g["other"]) + len(g["extra"]) for g in groups)
    leftover = total_unused - assigned
    if leftover:
        lines.append(f"Note: {leftover} unused word(s) remain unassigned in the final partial group.")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    raw = load_words()
    unused = dedupe_unused(raw)
    groups = build_groups(unused)
    text = format_groups(groups, len(unused))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(text, encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    print(f"Unused words: {len(unused)} | Groups: {len(groups)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
