#!/usr/bin/env python3
"""
Build 19 vocabulary groups aligned to distr-reference templates (dist-1..dist-4).

Produces:
  - dist-optimized-19.txt          (dist-4 weighted highest)
  - dist-equal-weight-comparison.txt (equal weights + diff vs dist-4-weighted)
"""

from __future__ import annotations

import csv
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REF_DIR = ROOT / "cursor-claude-common/references/final words"
DIST_DIR = ROOT / "cursor-claude-common/references/distr-references"
OUTPUT_DIST4 = DIST_DIR / "dist-optimized-19.txt"
OUTPUT_EQUAL_COMPARE = DIST_DIR / "dist-equal-weight-comparison.txt"

WEIGHTS_DIST4_HEAVY = {
    "dist-4.txt": 4,
    "dist-3.txt": 2,
    "dist-2.txt": 2,
    "dist-1.txt": 1,
}

WEIGHTS_EQUAL = {
    "dist-1.txt": 1,
    "dist-2.txt": 1,
    "dist-3.txt": 1,
    "dist-4.txt": 1,
}

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

VERB_KINDS = frozenset({"verb", "common_verb"})
ADJ_ADV_KINDS = frozenset({"adj", "adv"})
OTHER_KINDS = frozenset({"adj", "adv", "prep", "aux", "conj", "noun"})

FILE_PARSERS = {
    "dist-1.txt": None,  # set below
    "dist-2.txt": None,
    "dist-3.txt": None,
    "dist-4.txt": None,
}


@dataclass
class Word:
    word: str
    kind: str
    cefr: str
    rank: int

    @property
    def key(self) -> str:
        return normalize_key(self.word)

    def display(self) -> str:
        if self.kind in VERB_KINDS:
            w = self.word.strip()
            return w if w.lower().startswith("to ") else f"to {w}"
        return self.word


@dataclass
class GroupTemplate:
    verbs: list[str] = field(default_factory=list)
    adj_adv: list[str] = field(default_factory=list)
    other: list[str] = field(default_factory=list)


def normalize_key(text: str) -> str:
    s = " ".join((text or "").strip().split()).lower()
    if s.startswith("to "):
        s = s[3:].strip()
    return s


def split_words(text: str) -> list[str]:
    return [w.strip() for w in re.split(r",\s*", text.strip()) if w.strip()]


def parse_dist1(path: Path) -> dict[int, GroupTemplate]:
    groups: dict[int, GroupTemplate] = {}
    current: int | None = None
    section: str | None = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        m = re.match(r"Group\s+(\d+)", line, re.I)
        if m:
            current = int(m.group(1))
            groups[current] = GroupTemplate()
            section = None
            continue
        if current is None:
            continue
        low = line.lower()
        if low == "verbs":
            section = "verbs"
            continue
        if "adjective" in low or low.startswith("adj"):
            section = "adj_adv"
            continue
        if low == "mixed":
            section = "other"
            continue
        if section == "verbs":
            groups[current].verbs.append(line)
        elif section == "adj_adv":
            groups[current].adj_adv.append(line)
        elif section == "other":
            groups[current].other.append(line)
    return groups


def parse_dist2(path: Path) -> dict[int, GroupTemplate]:
    groups: dict[int, GroupTemplate] = {}
    current: int | None = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        m = re.match(r"Group\s+(\d+)\s*$", line, re.I)
        if m:
            current = int(m.group(1))
            groups[current] = GroupTemplate()
            continue
        if current is None:
            continue
        if line.lower().startswith("verbs:"):
            groups[current].verbs = split_words(line.split(":", 1)[1])
        elif "adjective" in line.lower():
            groups[current].adj_adv = split_words(line.split(":", 1)[1])
        elif line.lower().startswith("mixed:"):
            groups[current].other = split_words(line.split(":", 1)[1])
    return groups


def parse_dist3_or_4(path: Path) -> dict[int, GroupTemplate]:
    groups: dict[int, GroupTemplate] = {}
    current: int | None = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        m = re.match(r"Group\s+(\d+)", line, re.I)
        if m:
            current = int(m.group(1))
            groups[current] = GroupTemplate()
            continue
        if current is None:
            continue
        low = line.lower()
        if low.startswith("verbs"):
            groups[current].verbs = split_words(line.split(":", 1)[1])
        elif low.startswith("adj/adv (4)") or low.startswith("adj/adv:"):
            groups[current].adj_adv = split_words(line.split(":", 1)[1])
        elif low.startswith("other"):
            groups[current].other = split_words(line.split(":", 1)[1])
        elif "adj/adv/noun/prep" in low:
            groups[current].other = split_words(line.split(":", 1)[1])
    return groups


FILE_PARSERS.update(
    {
        "dist-1.txt": parse_dist1,
        "dist-2.txt": parse_dist2,
        "dist-3.txt": parse_dist3_or_4,
        "dist-4.txt": parse_dist3_or_4,
    }
)


def load_vocabulary() -> tuple[list[Word], dict[str, int]]:
    rows: list[Word] = []
    usage: dict[str, int] = {}
    for kind, filename in FILES:
        with (REF_DIR / filename).open(encoding="utf-8") as f:
            for rank, row in enumerate(csv.DictReader(f), start=1):
                word = (row.get("word") or "").strip()
                if not word:
                    continue
                key = normalize_key(word)
                count = int((row.get("count") or "0").strip() or 0)
                usage[key] = max(usage.get(key, 0), count)
                rows.append(
                    Word(
                        word=word,
                        kind=kind,
                        cefr=(row.get("level") or "").strip(),
                        rank=rank,
                    )
                )
    best: dict[str, Word] = {}
    for row in rows:
        prev = best.get(row.key)
        if prev is None or KIND_PRIORITY[row.kind] < KIND_PRIORITY[prev.kind]:
            best[row.key] = row
    return list(best.values()), usage


def merge_templates(weights: dict[str, int]) -> dict[int, dict[str, dict[str, float]]]:
    merged: dict[int, dict[str, dict[str, float]]] = defaultdict(
        lambda: {
            "verbs": defaultdict(float),
            "adj_adv": defaultdict(float),
            "other": defaultdict(float),
        }
    )
    for filename, parser in FILE_PARSERS.items():
        path = DIST_DIR / filename
        weight = weights[filename]
        parsed = parser(path)
        for gnum, tmpl in parsed.items():
            for slot, words in (
                ("verbs", tmpl.verbs),
                ("adj_adv", tmpl.adj_adv),
                ("other", tmpl.other),
            ):
                for w in words:
                    merged[gnum][slot][normalize_key(w)] += weight
    return merged


def effective_cefr(w: Word) -> str:
    if w.cefr:
        return w.cefr
    if w.kind in {"common_verb", "noun"}:
        return "A1"
    return ""


def freq_key(w: Word) -> tuple:
    return (CEFR_ORDER.get(effective_cefr(w), 9), w.rank, w.word.lower())


def pick_words(
    pool: list[Word],
    used: set[str],
    targets: dict[str, float],
    n: int,
    allowed_kinds: frozenset[str],
) -> list[Word]:
    candidates = [w for w in pool if w.key not in used and w.kind in allowed_kinds]

    def score(w: Word) -> tuple:
        return (-targets.get(w.key, 0), freq_key(w))

    candidates.sort(key=score)
    picked: list[Word] = []
    for w in candidates:
        if len(picked) >= n:
            break
        picked.append(w)
        used.add(w.key)
    return picked


def build_groups(
    templates: dict[int, dict[str, dict[str, float]]],
    vocab: list[Word],
) -> list[dict[str, list[Word]]]:
    used: set[str] = set()
    groups: list[dict[str, list[Word]]] = []
    verb_pool = [w for w in vocab if w.kind in VERB_KINDS]
    adj_adv_pool = [w for w in vocab if w.kind in ADJ_ADV_KINDS]
    other_pool = [w for w in vocab if w.kind in OTHER_KINDS]

    for gnum in range(1, 20):
        tmpl = templates.get(gnum, {"verbs": {}, "adj_adv": {}, "other": {}})
        groups.append(
            {
                "verbs": pick_words(verb_pool, used, tmpl["verbs"], 9, VERB_KINDS),
                "adj_adv": pick_words(
                    adj_adv_pool, used, tmpl["adj_adv"], 4, ADJ_ADV_KINDS
                ),
                "other": pick_words(other_pool, used, tmpl["other"], 6, OTHER_KINDS),
            }
        )
    return groups


def group_word_keys(group: dict[str, list[Word]]) -> set[str]:
    keys: set[str] = set()
    for slot in ("verbs", "adj_adv", "other"):
        keys.update(w.key for w in group[slot])
    return keys


def group_words_by_slot(group: dict[str, list[Word]]) -> dict[str, list[str]]:
    return {
        "verbs": [w.display() for w in group["verbs"]],
        "adj_adv": [w.display() for w in group["adj_adv"]],
        "other": [w.display() for w in group["other"]],
    }


def template_from_parsed(g: GroupTemplate | None) -> dict[str, dict[str, float]]:
    tmpl: dict[str, dict[str, float]] = {
        "verbs": defaultdict(float),
        "adj_adv": defaultdict(float),
        "other": defaultdict(float),
    }
    if not g:
        return tmpl
    for slot, words in (
        ("verbs", g.verbs),
        ("adj_adv", g.adj_adv),
        ("other", g.other),
    ):
        for w in words:
            tmpl[slot][normalize_key(w)] += 1
    return tmpl


def compute_overlap(
    group: dict[str, list[Word]],
    tmpl: dict[str, dict[str, float]],
) -> tuple[int, int]:
    slot_map = {"verbs": group["verbs"], "adj_adv": group["adj_adv"], "other": group["other"]}
    total = matched = 0.0
    for slot, targets in tmpl.items():
        keys = {w.key for w in slot_map.get(slot, [])}
        for word, weight in targets.items():
            total += weight
            if word in keys:
                matched += weight
    return int(matched), int(total)


def alignment_summary(
    groups: list[dict[str, list[Word]]],
    weights: dict[str, int],
) -> list[str]:
    lines = ["Alignment summary (word overlap with each reference file)", ""]
    for fname in ("dist-4.txt", "dist-3.txt", "dist-2.txt", "dist-1.txt"):
        parsed = FILE_PARSERS[fname](DIST_DIR / fname)
        matched = total = 0
        for gnum in range(1, 20):
            m, t = compute_overlap(groups[gnum - 1], template_from_parsed(parsed.get(gnum)))
            matched += m
            total += t
        pct = (100 * matched / total) if total else 0
        lines.append(
            f"  {fname} (weight ×{weights[fname]}): "
            f"{matched}/{total} target slots matched ({pct:.0f}%)"
        )
    return lines


def format_group_block(
    group: dict[str, list[Word]],
    gnum: int,
    *,
    label: str,
) -> list[str]:
    verbs = group["verbs"]
    adj_adv = group["adj_adv"]
    other = group["other"]
    total = len(verbs) + len(adj_adv) + len(other)
    return [
        f"Group {gnum} ({total} words) — {label}",
        "",
        f"Verbs (9): {', '.join(w.display() for w in verbs) or '—'}",
        f"Adj/Adv (4): {', '.join(w.display() for w in adj_adv) or '—'}",
        f"Other (6): {', '.join(w.display() for w in other) or '—'}",
        "",
    ]


def format_dist4_output(
    groups: list[dict[str, list[Word]]],
    weights: dict[str, int],
) -> str:
    lines = [
        "Optimized 19-group vocabulary (unused words only)",
        "=" * 72,
        "",
        "Aligned to distr-references dist-1..dist-4 with weights:",
        f"  dist-4.txt ×{weights['dist-4.txt']}  |  "
        f"dist-3.txt ×{weights['dist-3.txt']}  |  "
        f"dist-2.txt ×{weights['dist-2.txt']}  |  "
        f"dist-1.txt ×{weights['dist-1.txt']}",
        "",
        "Structure per group: 9 verbs + 4 adj/adv (WordPairs) + 6 other (adj/adv/noun/prep)",
        "",
    ]
    for i, group in enumerate(groups, start=1):
        lines.extend(format_group_block(group, i, label="dist-4 weighted"))
    lines.append("=" * 72)
    lines.extend(alignment_summary(groups, weights))
    lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def format_equal_and_comparison(
    equal_groups: list[dict[str, list[Word]]],
    dist4_groups: list[dict[str, list[Word]]],
) -> str:
    lines = [
        "Equal-weight 19-group vocabulary + comparison vs dist-4-weighted",
        "=" * 72,
        "",
        "SECTION A — Equal-weight groups (dist-1..dist-4 all ×1)",
        "",
        "Structure per group: 9 verbs + 4 adj/adv (WordPairs) + 6 other (adj/adv/noun/prep)",
        "",
    ]
    for i, group in enumerate(equal_groups, start=1):
        lines.extend(format_group_block(group, i, label="equal weight"))

    lines.extend(
        alignment_summary(equal_groups, WEIGHTS_EQUAL)
    )
    lines.append("")
    lines.append("=" * 72)
    lines.append("SECTION B — Comparison: equal-weight vs dist-4-weighted (dist-optimized-19)")
    lines.append("")

    total_same = total_only_equal = total_only_dist4 = 0
    identical_groups = 0

    for i in range(19):
        gnum = i + 1
        eq = equal_groups[i]
        d4 = dist4_groups[i]
        eq_keys = group_word_keys(eq)
        d4_keys = group_word_keys(d4)
        same = eq_keys & d4_keys
        only_equal = eq_keys - d4_keys
        only_dist4 = d4_keys - eq_keys
        total_same += len(same)
        total_only_equal += len(only_equal)
        total_only_dist4 += len(only_dist4)
        if eq_keys == d4_keys:
            identical_groups += 1

        lines.append(f"--- Group {gnum} ---")
        lines.append(f"  Same ({len(same)}): {', '.join(sorted(same)) or '—'}")
        lines.append(
            f"  Only equal-weight ({len(only_equal)}): "
            f"{', '.join(sorted(only_equal)) or '—'}"
        )
        lines.append(
            f"  Only dist-4-weighted ({len(only_dist4)}): "
            f"{', '.join(sorted(only_dist4)) or '—'}"
        )

        # Slot-level diffs when words differ
        eq_slots = group_words_by_slot(eq)
        d4_slots = group_words_by_slot(d4)
        for slot, title in (
            ("verbs", "Verbs"),
            ("adj_adv", "Adj/Adv"),
            ("other", "Other"),
        ):
            if eq_slots[slot] != d4_slots[slot]:
                lines.append(f"  {title} equal:     {', '.join(eq_slots[slot]) or '—'}")
                lines.append(f"  {title} dist-4:    {', '.join(d4_slots[slot]) or '—'}")
        lines.append("")

    lines.append("=" * 72)
    lines.append("Comparison totals (across all 19 groups)")
    lines.append("")
    lines.append(f"  Words in both versions:        {total_same}")
    lines.append(f"  Words only in equal-weight:    {total_only_equal}")
    lines.append(f"  Words only in dist-4-weighted: {total_only_dist4}")
    lines.append(f"  Groups with identical 19 words: {identical_groups}/19")
    lines.append("")
    lines.append("Reference alignment contrast:")
    lines.extend(alignment_summary(equal_groups, WEIGHTS_EQUAL))
    lines.append("")
    lines.append("vs dist-4-weighted:")
    lines.extend(alignment_summary(dist4_groups, WEIGHTS_DIST4_HEAVY))
    lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    vocab, usage = load_vocabulary()
    unused_vocab = [w for w in vocab if usage.get(w.key, 0) == 0]

    tmpl_dist4 = merge_templates(WEIGHTS_DIST4_HEAVY)
    tmpl_equal = merge_templates(WEIGHTS_EQUAL)
    groups_dist4 = build_groups(tmpl_dist4, unused_vocab)
    groups_equal = build_groups(tmpl_equal, unused_vocab)

    OUTPUT_DIST4.write_text(
        format_dist4_output(groups_dist4, WEIGHTS_DIST4_HEAVY),
        encoding="utf-8",
    )
    OUTPUT_EQUAL_COMPARE.write_text(
        format_equal_and_comparison(groups_equal, groups_dist4),
        encoding="utf-8",
    )

    print(f"Wrote {OUTPUT_DIST4}")
    print(f"Wrote {OUTPUT_EQUAL_COMPARE}")
    print(f"Unused pool: {len(unused_vocab)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
