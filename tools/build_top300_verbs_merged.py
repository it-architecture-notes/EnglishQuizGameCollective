#!/usr/bin/env python3
"""
Build top-300 Oxford verbs by cross-source frequency (Borda-style sum of ranks),
merge metadata with full Oxford verb list, write JSON under cursor-claude-common/references/.
"""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFS = ROOT / "cursor-claude-common/references"

OXFORD_VERBS_JSON = REFS / "3000 words oxford verbs.json"
HIGH_FREQ = REFS / "high-freq-2000.txt"
EF_3000 = REFS / "efdotcom-mostcommon-3000.txt"
UNIGRAM = REFS / "unigram_freq.csv"
LEMMAS = REFS / "1 lemmas-Table 1.csv"
OUT_JSON = REFS / "top300-verbs-freq-merged.json"


def normalize_lookup_key(lemma: str) -> str:
    """Map Oxford headword variants to a token for corpus lookup (unigram / HF / lemmas)."""
    s = lemma.strip().lower()
    if not s:
        return s
    # First word before space (handles "like (find ...)", "used to", "last1 (taking time)")
    if " " in s:
        s = s.split()[0]
    # can1, wind2, live1 -> base
    s = re.sub(r"\d+$", "", s)
    return s


def load_high_freq(path: Path) -> dict[str, int]:
    """word -> 1-based rank (1 = most common)."""
    out: dict[str, int] = {}
    rx = re.compile(r"^\s*(\d+)\.\s+(\S+)\s*$")
    for line in path.read_text(encoding="utf-8").splitlines():
        m = rx.match(line)
        if not m:
            continue
        rank = int(m.group(1))
        w = m.group(2).strip().lower()
        out[w] = rank
    return out


def load_ef_set(path: Path) -> set[str]:
    return {ln.strip().lower() for ln in path.read_text(encoding="utf-8").splitlines() if ln.strip()}


def load_unigram(path: Path) -> tuple[dict[str, int], dict[str, int]]:
    """Returns (word -> count, word -> rank by descending count)."""
    counts: dict[str, int] = {}
    with path.open(encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            w = row["word"].strip().lower()
            counts[w] = int(row["count"])
    sorted_words = sorted(counts.keys(), key=lambda w: counts[w], reverse=True)
    rank = {w: i + 1 for i, w in enumerate(sorted_words)}
    return counts, rank


def load_lemmas(path: Path) -> tuple[dict[str, int], dict[str, int]]:
    """lemma -> best (minimum) rank; lemma -> max freq across duplicate rows."""
    best_rank: dict[str, int] = {}
    best_freq: dict[str, int] = {}
    with path.open(encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            lem = row["lemma"].strip().lower()
            rk = int(row["rank"])
            fq = int(row["freq"])
            if lem not in best_rank or rk < best_rank[lem]:
                best_rank[lem] = rk
            if lem not in best_freq or fq > best_freq[lem]:
                best_freq[lem] = fq
    return best_rank, best_freq


def borda_points(rank: int | None, n: int) -> float:
    if rank is None or rank < 1:
        return 0.0
    return float(n + 1 - rank)


def main() -> None:
    oxford_data = json.loads(OXFORD_VERBS_JSON.read_text(encoding="utf-8"))
    oxford_verbs: list[str] = oxford_data["verbs"]

    hf = load_high_freq(HIGH_FREQ)
    ef = load_ef_set(EF_3000)
    uni_counts, uni_rank = load_unigram(UNIGRAM)
    lem_rank, lem_freq = load_lemmas(LEMMAS)

    n_hf = max(hf.values(), default=0)
    n_uni = len(uni_rank)
    n_lem = max(lem_rank.values(), default=0)

    rows: list[dict] = []
    for lemma in oxford_verbs:
        key = normalize_lookup_key(lemma)

        r_hf = hf.get(key)
        r_uni = uni_rank.get(key)
        r_lem = lem_rank.get(key)

        p_hf = borda_points(r_hf, n_hf)
        p_uni = borda_points(r_uni, n_uni)
        p_lem = borda_points(r_lem, n_lem)
        in_ef = 1.0 if key in ef else 0.0

        # Weight EF membership slightly (list is alphabetical; presence still signals curriculum overlap).
        composite = p_hf + p_uni + p_lem + 0.15 * in_ef * (n_hf / 2.0)

        rows.append(
            {
                "lemma": lemma,
                "lookup_key": key,
                "ranks": {
                    "high_freq_2000": r_hf,
                    "unigram": r_uni,
                    "lemmas_table": r_lem,
                },
                "counts": {
                    "unigram": uni_counts.get(key),
                    "lemmas_table_freq": lem_freq.get(key),
                },
                "in_efdotcom_3000": bool(in_ef),
                "borda": {
                    "high_freq": round(p_hf, 6),
                    "unigram": round(p_uni, 6),
                    "lemmas_table": round(p_lem, 6),
                    "ef_membership_bonus": round(0.15 * in_ef * (n_hf / 2.0), 6),
                },
                "composite_score": round(composite, 6),
            }
        )

    rows.sort(key=lambda x: x["composite_score"], reverse=True)
    top_300 = rows[:300]

    payload = {
        "description": (
            "Oxford 3000 verb lemmas scored by Borda-style points from: high-freq-2000 rank, "
            "unigram_freq.csv rank (by count), 1 lemmas-Table 1.csv rank (best rank per lemma); "
            "small bonus if lookup_key appears in efdotcom-mostcommon-3000.txt. "
            "Lookup uses normalize_lookup_key(lemma) for matching corpora."
        ),
        "sources": {
            "oxford_verbs_json": str(OXFORD_VERBS_JSON.relative_to(ROOT)),
            "high_freq_2000": str(HIGH_FREQ.relative_to(ROOT)),
            "efdotcom_3000": str(EF_3000.relative_to(ROOT)),
            "unigram_freq": str(UNIGRAM.relative_to(ROOT)),
            "lemmas_table": str(LEMMAS.relative_to(ROOT)),
        },
        "oxford_verb_count": len(oxford_verbs),
        "oxford_verbs": oxford_verbs,
        "top_300_verbs_by_frequency": [r["lemma"] for r in top_300],
        "top_300_detail": top_300,
        "note": "top_300_verbs_by_frequency is a subset of oxford_verbs (Oxford lemma set ∩ frequency ranking).",
    }

    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_JSON} ({len(oxford_verbs)} Oxford verbs, top 300 rows)")


if __name__ == "__main__":
    main()
