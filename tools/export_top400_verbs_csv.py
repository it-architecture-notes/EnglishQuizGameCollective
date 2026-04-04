#!/usr/bin/env python3
"""
Score Oxford verb lemmas by cross-source frequency (same Borda scheme as build_top300_verbs_merged.py),
assign CEFR from 3000 words oxford.txt (minimum level among verb senses on the headword line),
write cursor-claude-common/references/final words/verbs-400.csv (verb, level).
"""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFS = ROOT / "cursor-claude-common/references"
FINAL_WORDS = REFS / "final words"

OXFORD_TXT = REFS / "3000 words oxford.txt"
OXFORD_VERBS_JSON = REFS / "3000 words oxford verbs.json"
HIGH_FREQ = REFS / "high-freq-2000.txt"
EF_3000 = REFS / "efdotcom-mostcommon-3000.txt"
UNIGRAM = REFS / "unigram_freq_full.csv"
LEMMAS = REFS / "1 lemmas-Table 1.csv"
OUT_CSV = FINAL_WORDS / "verbs-400.csv"

CEFR_ORDER = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}

TOP_N = 400

verb_token = re.compile(r"(?<![a-z])v\.")
# Allow Oxford slash-compounds (e.g. adj./pron., conj./prep.) after the POS tag.
pos_start = re.compile(
    r"\s+(?:"
    r"n\.|v\.|adj\.(?:/[^,\s]+)*|adv\.(?:/[^,\s]+)*|prep\.(?:/[^,\s]+)*|"
    r"conj\.(?:/[^,\s]+)*|pron\.(?:/[^,\s]+)*|det\.|exclam\.|"
    r"number|modal|indefinite article"
    r")(?=\s|$|,)"
)


def normalize_lookup_key(lemma: str) -> str:
    s = lemma.strip().lower()
    if not s:
        return s
    if " " in s:
        s = s.split()[0]
    s = re.sub(r"\d+$", "", s)
    return s


def merge_oxford_raw_lines(lines: list[str]) -> list[str]:
    """Merge continuation lines broken across rows in the Oxford source text."""
    lines = [ln.rstrip("\n") for ln in lines]
    out: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if not line.strip():
            continue
        while i < len(lines):
            nxt = lines[i].strip()
            if not nxt:
                i += 1
                continue
            join = False
            if line.rstrip().endswith(",") and re.match(
                r"^(adj\.|adv\.|n\.|v\.|prep\.|conj\.|pron\.|det\.|exclam\.)", nxt
            ):
                join = True
            if re.match(r"^\s*v\.\s+[ABC][12]", nxt) and line.rstrip().endswith(","):
                join = True
            if not join:
                break
            line = line.rstrip() + " " + nxt
            i += 1
        out.append(line)
    return out


def extract_lemma(line: str) -> str | None:
    m = pos_start.search(line)
    if not m:
        return None
    return line[: m.start()].strip()


def verb_cefr_levels(line: str) -> list[str]:
    """CEFR tags tied to verb / modal v. senses (not adv., etc.)."""
    levels: list[str] = []
    for m in re.finditer(r"(?<![a-z])modal\s+v\.\s*([ABC][12])", line):
        levels.append(m.group(1))
    for m in re.finditer(r"(?<![a-z])v\.\s*([ABC][12])", line):
        levels.append(m.group(1))
    # e.g. help v., n. A1 — level after noun on same headword line
    for m in re.finditer(r"(?<![a-z])v\.\s*,\s*n\.\s*([ABC][12])", line):
        levels.append(m.group(1))
    for m in re.finditer(r"(?<![a-z])v\.\s*,\s*adj\.\s*([ABC][12])", line):
        levels.append(m.group(1))
    for m in re.finditer(r"(?<![a-z])v\.\s*,\s*adv\.\s*([ABC][12])", line):
        levels.append(m.group(1))
    for m in re.finditer(r"(?<![a-z])v\.\s*,\s*prep\.\s*([ABC][12])", line):
        levels.append(m.group(1))
    return levels


def min_cefr(levels: list[str]) -> str | None:
    if not levels:
        return None
    return min(levels, key=lambda x: CEFR_ORDER.get(x, 99))


def load_oxford_verb_cefr_map(path: Path) -> dict[str, str]:
    """normalize_lookup_key(lemma) -> easiest CEFR among verb senses (collapses homograph headwords)."""
    raw = path.read_text(encoding="utf-8").splitlines()
    merged = merge_oxford_raw_lines(raw)
    best: dict[str, str] = {}

    def consider_lemma(lemma: str, level: str) -> None:
        key = normalize_lookup_key(lemma)
        if not key:
            return
        if key not in best or CEFR_ORDER[level] < CEFR_ORDER[best[key]]:
            best[key] = level

    for line in merged:
        s = line.strip()
        if not s or s.startswith("The Oxford 3000"):
            continue
        if "©" in s and "Oxford University Press" in s:
            continue
        if not verb_token.search(line):
            continue
        lemma = extract_lemma(line)
        if not lemma:
            continue
        levels = verb_cefr_levels(line)
        m = min_cefr(levels)
        if m:
            consider_lemma(lemma, m)

    return best


def load_high_freq(path: Path) -> dict[str, int]:
    out: dict[str, int] = {}
    rx = re.compile(r"^\s*(\d+)\.\s+(\S+)\s*$")
    for line in path.read_text(encoding="utf-8").splitlines():
        m = rx.match(line)
        if not m:
            continue
        out[m.group(2).strip().lower()] = int(m.group(1))
    return out


def load_ef_set(path: Path) -> set[str]:
    return {ln.strip().lower() for ln in path.read_text(encoding="utf-8").splitlines() if ln.strip()}


def load_unigram(path: Path) -> tuple[dict[str, int], dict[str, int]]:
    counts: dict[str, int] = {}
    with path.open(encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            w = row["word"].strip().lower()
            counts[w] = int(row["count"])
    sorted_words = sorted(counts.keys(), key=lambda w: counts[w], reverse=True)
    rank = {w: i + 1 for i, w in enumerate(sorted_words)}
    return counts, rank


def load_lemmas(path: Path) -> dict[str, int]:
    best_rank: dict[str, int] = {}
    with path.open(encoding="utf-8", newline="") as f:
        r = csv.DictReader(f)
        for row in r:
            lem = row["lemma"].strip().lower()
            rk = int(row["rank"])
            if lem not in best_rank or rk < best_rank[lem]:
                best_rank[lem] = rk
    return best_rank


def borda_points(rank: int | None, n: int) -> float:
    if rank is None or rank < 1:
        return 0.0
    return float(n + 1 - rank)


def main() -> None:
    if not UNIGRAM.exists():
        raise SystemExit(f"Missing unigram file: {UNIGRAM}")

    cefr_by_lookup = load_oxford_verb_cefr_map(OXFORD_TXT)
    oxford_verbs: list[str] = json.loads(OXFORD_VERBS_JSON.read_text(encoding="utf-8"))["verbs"]

    hf = load_high_freq(HIGH_FREQ)
    ef = load_ef_set(EF_3000)
    _, uni_rank = load_unigram(UNIGRAM)
    lem_rank = load_lemmas(LEMMAS)

    n_hf = max(hf.values(), default=0)
    n_uni = len(uni_rank)
    n_lem = max(lem_rank.values(), default=0)

    scored: list[tuple[float, str]] = []
    for lemma in oxford_verbs:
        key = normalize_lookup_key(lemma)
        r_hf = hf.get(key)
        r_uni = uni_rank.get(key)
        r_lem = lem_rank.get(key)
        p_hf = borda_points(r_hf, n_hf)
        p_uni = borda_points(r_uni, n_uni)
        p_lem = borda_points(r_lem, n_lem)
        in_ef = 1.0 if key in ef else 0.0
        composite = p_hf + p_uni + p_lem + 0.15 * in_ef * (n_hf / 2.0)
        scored.append((composite, lemma))

    scored.sort(key=lambda x: (-x[0], x[1].lower()))
    top = [lemma for _, lemma in scored[:TOP_N]]

    FINAL_WORDS.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["verb", "level"])
        for lemma in top:
            level = cefr_by_lookup.get(normalize_lookup_key(lemma)) or ""
            w.writerow([lemma, level])

    print(f"Wrote {OUT_CSV} ({TOP_N} rows + header)")


if __name__ == "__main__":
    main()
