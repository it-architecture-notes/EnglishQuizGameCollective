#!/usr/bin/env python3
"""
Scan all game-flow levels for grammar-progression violations (audit-quiz-level SKILL).
Outputs markdown report to cursor-claude-common/output/all-levels-grammar-progression-audit.md

The Part 1-4 band model this script checks against is the ADULT grammar
progression (see cursor-claude-common/skills/audit-quiz-level/SKILL.md) — kids
content uses its own smaller, ML-independent grammar set instead (see
cursor-claude-common/skills/simplify-kids-level-content/SKILL.md) and this
script's Part bands do not apply to it. Defaults to --flavor adults for that
reason; pass --flavor kids only if you specifically want to see how far kids
content (which is intentionally simpler) diverges from the adult bands.

Usage:
  python3 tools/audit_grammar_progression.py
  python3 tools/audit_grammar_progression.py --flavor kids
"""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FLOW = ROOT / "app/assets/data/flow/game-flow.json"
LEVELS = ROOT / "app/assets/quiz-data/levels"
OUT = ROOT / "cursor-claude-common/output/all-levels-grammar-progression-audit.md"


def questions_path(name: str, flavor: str) -> Path:
    """Prefer {level}/{flavor}/questions.json; fall back to the legacy
    root {level}/questions.json for any level not (yet) flavor-split."""
    flavored = LEVELS / name / flavor / "questions.json"
    if flavored.is_file():
        return flavored
    return LEVELS / name / "questions.json"


def flow_level_name(entry: dict) -> str | None:
    """Real levels key on directoryName (schema since the flow-JSON flavor
    split); reminder entries (kind == "reminder") have no directoryName and
    aren't standalone levels — skip them."""
    if entry.get("kind") == "reminder":
        return None
    name = entry.get("directoryName") or entry.get("iconImageName")
    return name if isinstance(name, str) and name.strip() else None

SKIP_TOP_KEYS = frozenset(
    {"template", "character1", "character2", "imageName", "timer_seconds",
     "audio_file", "audio_file1", "audio_file2"}
)

# Base-form homographs excluded from irregular-past scan
HOMOGRAPH_BASE = frozenset(
    {
        "read", "let", "set", "put", "cut", "hit", "hurt", "shut", "split", "cost",
        "spread", "shed", "bid", "quit", "upset", "wet", "bet",
    }
)

# Adjective / participle used as adjective — not passive teaching
ADJ_ED = frozenset(
    {
        "tired", "closed", "open", "excited", "bored", "interested", "worried",
        "scared", "relaxed", "surprised", "pleased", "confused", "advanced",
        "related", "detailed", "limited", "fixed", "learned", "reserved",
        "green", "red", "advanced", "wicked", "naked", "wicked",
    }
)


def ml_part(ml: int) -> int:
    if ml <= 3:
        return 1
    if ml <= 5:
        return 2
    if ml <= 8:
        return 3
    return 4


PART_NAMES = {
    1: "Part 1 (ML1–3): Present Simple, can, continuous, There is/are",
    2: "Part 2 (ML4–5): will/going to, must, comparatives, 1st conditional",
    3: "Part 3 (ML6–8): Past Simple, should, have to, could/might",
    4: "Part 4 (ML9–12): Present Perfect, passive, past continuous, 2nd conditional, reported speech",
}


def collect_qd_strings(qd: dict) -> list[tuple[str, str]]:
    """(location, text) from questionData only."""
    out: list[tuple[str, str]] = []

    def add(loc: str, val) -> None:
        if isinstance(val, str) and val.strip():
            out.append((loc, val.strip()))
        elif isinstance(val, list):
            for i, x in enumerate(val):
                if isinstance(x, str) and x.strip():
                    out.append((f"{loc}[{i}]", x.strip()))

    for key in ("line1", "line2", "sentence", "words", "answer", "correct_order"):
        if key in qd:
            add(f"questionData.{key}", qd[key])
    for key in ("distractors", "wrongAnswers"):
        if key in qd:
            add(f"questionData.{key}", qd[key])
    return out


IRREGULAR_PAST_RE = re.compile(
    r"\b(?:went|came|forgot|left|made|said|got|took|saw|thought|knew|found|gave|"
    r"brought|bought|fought|looked|walked|talked|played|worked|lived|moved|opened|"
    r"closed|started|stopped|helped|wanted|needed|liked|loved|hated|finished|"
    r"happened|remembered|believed|heard|felt|kept|slept|sent|spent|built|chose|"
    r"drank|drove|ate|fell|grew|held|hid|led|lost|met|paid|ran|rode|sat|sold|"
    r"spoke|stood|stuck|taught|threw|understood|woke|won|wrote|became|began|"
    r"broke|caught|flew|forgave|froze|forgave|drew|flew|forgave|forgave|"
    r"ate|broke|brought|built|bought|caught|chose|did|drew|drank|drove|ate|fell|"
    r"fought|found|got|gave|went|grew|had|heard|held|hid|hit|hurt|kept|knew|"
    r"laid|led|let|lay|lost|made|meant|met|paid|put|read|rode|rang|rose|ran|"
    r"said|saw|sold|sent|set|shook|shone|shot|showed|shut|sang|sank|sat|slept|"
    r"spoke|spent|spread|stood|stole|stuck|struck|swam|took|taught|tore|told|"
    r"thought|threw|understood|woke|wore|won|wrote|logged|designed|considered|"
    r"recognized|realised|realized|reached|refused|increased|fixed|replied|"
    r"organized|achieved|disappeared|recorded|promised|managed|escaped|pointed|"
    r"killed|lasted|predicted|preferred|placed|owned|destroyed|accepted|published|"
    r"solved|voted|worried|pronounced|attacked|depended|referred|rose|shocked|"
    r"waited|turned|stayed|called|walked|arrived|stayed|came)\b",
    re.I,
)

LETS_RE = re.compile(r"\blet(?:'s|s)\b|\blet me\b|\blet us\b", re.I)
TURN_LEFT_RE = re.compile(r"\bturn\s+left\b", re.I)


def is_false_positive_irregular(text: str, match: re.Match[str]) -> bool:
    word = match.group(0).lower()
    if word in HOMOGRAPH_BASE:
        return True
    if LETS_RE.search(text):
        return True
    if word == "left" and TURN_LEFT_RE.search(text):
        return True
    if word == "met" and re.search(r"\bmeet\b", text, re.I):
        return True
    if word == "read" and re.search(r"\b(?:to|please|can|you|I)\s+read\b", text, re.I):
        return True
    return False


def check_text(text: str, level_part: int, *, is_distractor: bool) -> list[tuple[str, str, str]]:
    """Returns list of (severity, label, snippet)."""
    hits: list[tuple[str, str, str]] = []
    t = text

    def add(sev: str, label: str) -> None:
        hits.append((sev, label, t[:160]))

    # --- Part 2+ forbidden in Part 1 ---
    if level_part < 2:
        if re.search(r"\b(?:'m|am|is|are|was|were)\s+going\s+to\b", t, re.I):
            add("high", "be going to (Part 2)")
        elif re.search(r"\bgoing\s+to\s+(?:take|go|visit|eat|watch|meet|buy|see|get)\b", t, re.I):
            add("high", "going to + verb (Part 2)")
        if re.search(r"\bwill\s+(?:not\s+|n't\s+)?[a-z]", t, re.I):
            if not re.search(r"\bwill\s+(?:be\s+)?(?:fine|ready|back|do)\b", t, re.I):
                add("high", "will + verb (Part 2)")
        if re.search(r"\bmust\s+(?:not\s+|n't\s+)?[a-z]", t, re.I):
            add("high", "must (Part 2)")
        if re.search(r"\bif\s+[^.?!]{0,100}\bwill\b", t, re.I):
            add("high", "first conditional if…will (Part 2)")

    # --- Part 3+ forbidden in Part 1–2 ---
    if level_part < 3:
        if re.search(r"\b(?:was|were)\s+(?:not\s+|n't\s+)?[a-z]", t, re.I):
            w = re.search(r"\b(?:was|were)\s+(\w+)", t, re.I)
            if w and w.group(1).lower() not in ADJ_ED:
                add("high", "past be was/were (Part 3)")
        if re.search(r"\b(?:did|didn't|did\s+not)\s+[a-z]", t, re.I):
            sev = "low" if is_distractor else "high"
            add(sev, "Did question/negative (Part 3)")
        if re.search(r"\bshould\s+(?:not\s+|n't\s+)?[a-z]", t, re.I):
            sev = "low" if is_distractor else "high"
            add(sev, "should (Part 3)")
        if re.search(r"\b(?:have|has|had)\s+to\s+[a-z]", t, re.I):
            add("high", "have to (Part 3)")
        for m in IRREGULAR_PAST_RE.finditer(t):
            if is_false_positive_irregular(t, m):
                continue
            w = m.group(0).lower()
            # Past participle same spelling as past — only flag clear past uses
            if w in {"had", "did"} and is_distractor:
                add("low", f"irregular past `{w}` (distractor)")
            elif w in {"looked", "wanted", "needed", "walked", "talked", "played",
                       "worked", "moved", "started", "stopped", "helped", "finished",
                       "happened", "remembered", "believed", "waited", "turned",
                       "called", "arrived", "stayed", "opened", "closed", "liked"}:
                sev = "low" if is_distractor else "high"
                add(sev, f"past simple `{w}` (Part 3)")
            elif w in {"went", "came", "forgot", "left", "made", "said", "got", "took",
                       "saw", "gave", "brought", "bought", "fought", "ate", "fell",
                       "slept", "sent", "spent", "built", "chose", "drank", "drove",
                       "held", "lost", "paid", "ran", "rode", "sat", "sold", "spoke",
                       "stood", "taught", "threw", "won", "wrote", "became", "began",
                       "broke", "caught", "drew", "flew", "grew", "hid", "knew", "led",
                       "met", "rang", "rose", "sang", "sank", "shook", "stole", "swam",
                       "tore", "woke", "wore"}:
                sev = "low" if is_distractor else "high"
                add(sev, f"irregular past `{w}` (Part 3)")
        if re.search(r"\b\w+ed\b", t, re.I):
            if re.search(
                r"\b(?:yesterday|last\s+(?:night|week|month|year|Monday)|ago|in\s+\d{4})\b",
                t,
                re.I,
            ):
                add("high", "past -ed with time marker (Part 3)")

    # --- Part 4+ forbidden in Part 1–3 ---
    if level_part < 4:
        if re.search(
            r"\b(?:have|has)\s+(?!been\b)(?:\w+ed|\w+en|been|gone|seen|done|taken|given|"
            r"written|driven|eaten|broken|chosen|fallen|forgotten|hidden|known|left|"
            r"lost|met|paid|spoken|taught|thought|thrown|worn|won|built|caught|felt|"
            r"found|got|held|kept|led|made|meant|read|run|sat|sent|shut|slept|spent|"
            r"stood|told|understood|become|come|grown|shown|drawn|fought|dropped|"
            r"contained|controlled|managed|performed|promised|solved|recorded|destroyed|"
            r"accepted|published|voted|achieved|disappeared|fixed|pronounced|attacked|"
            r"referred|replied|risen|shocked|organized|depended|arrived|finished|started|"
            r"worked|lived|moved|happened)\b",
            t,
            re.I,
        ):
            if not re.search(r"\b(?:have|has)\s+(?:a|an|the|my|your|his|her|our|their|some|any|to)\b", t, re.I):
                add("high", "present perfect (Part 4)")
        if re.search(r"\b(?:was|were)\s+\w+ing\b", t, re.I):
            add("high", "past continuous (Part 4)")
        if re.search(r"\bused\s+to\s+[a-z]", t, re.I):
            add("high", "used to (Part 4)")
        if re.search(r"\bif\s+[^.?!]{0,100}\bwould\b", t, re.I):
            add("high", "second conditional if…would (Part 4)")
        if re.search(r"\bwould\s+have\s+\w+", t, re.I):
            add("high", "third conditional would have (Part 4)")
        if re.search(r"\bsaid\s+that\b", t, re.I):
            add("high", "reported speech said that (Part 4)")
        if re.search(r"\b(?:have|has)\s+been\s+\w+ing\b", t, re.I):
            add("high", "present perfect continuous (Part 4)")
        # Passive: be + past participle (exclude adjectives)
        pm = re.search(
            r"\b(?:am|is|are|was|were|been|be)\s+(\w+ed|\w+en)\b", t, re.I
        )
        if pm and pm.group(1).lower() not in ADJ_ED:
            # exclude "is due", "is fine"
            if pm.group(1).lower() not in {"due", "fine", "sure", "here", "there"}:
                if re.search(
                    r"\b(?:was|were)\s+(?:\w+ed|\w+en)\b", t, re.I
                ) and level_part < 4:
                    add("high", "passive / past participle predicate (Part 4)")

    return hits


def audit_question(item: dict, qnum: int, level_part: int) -> list[dict]:
    findings: list[dict] = []
    template = str(item.get("template", ""))
    qd = item.get("questionData")
    if not isinstance(qd, dict):
        return findings
    for loc, text in collect_qd_strings(qd):
        is_dist = "distractor" in loc or "wrongAnswer" in loc
        for sev, label, snippet in check_text(text, level_part, is_distractor=is_dist):
            findings.append(
                {
                    "q": qnum,
                    "template": template,
                    "location": loc,
                    "severity": sev,
                    "label": label,
                    "text": snippet,
                }
            )
    return findings


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--flavor", choices=("adults", "kids"), default="adults")
    args = p.parse_args()
    flavor = args.flavor

    flow = json.loads(FLOW.read_text(encoding="utf-8"))
    flow_map = {}
    for e in flow:
        name = flow_level_name(e)
        if name is not None:
            flow_map[name] = e

    all_findings: dict[str, list[dict]] = {}
    stats = defaultdict(lambda: {"levels": 0, "with_q": 0, "high": 0, "low": 0})

    for name, entry in flow_map.items():
        ml = entry["mainLevel"]
        part = ml_part(ml)
        stats[ml]["levels"] += 1
        qpath = questions_path(name, flavor)
        if not qpath.is_file():
            continue
        data = json.loads(qpath.read_text(encoding="utf-8"))
        qs = data.get("levelQuestions") or []
        if not qs:
            continue
        stats[ml]["with_q"] += 1

        level_hits: list[dict] = []
        for i, q in enumerate(qs, 1):
            if isinstance(q, dict):
                level_hits.extend(audit_question(q, i, part))
        if level_hits:
            all_findings[name] = level_hits
            for h in level_hits:
                stats[ml][h["severity"]] += 1

    lines = [
        "# All flow levels — grammar progression audit",
        "",
        "Scan of `questions.json` against audit-skill Part bands.",
        "Excludes audio stems; reduces false positives (`Let's`, base-form `read`, adjective `closed`).",
        "Includes distractors (low severity when clearly wrong options).",
        "",
        "## Summary by mainLevel",
        "",
        "| ML | Part | Levels w/ Q | High flags | Low flags (mostly distractors) |",
        "|----|------|-------------|------------|--------------------------------|",
    ]
    for ml in sorted(stats):
        s = stats[ml]
        if s["with_q"] == 0 and s["levels"] > 0:
            lines.append(f"| {ml} | {ml_part(ml)} | 0 | — | — |")
        elif s["levels"] > 0:
            lines.append(
                f"| {ml} | {ml_part(ml)} | {s['with_q']} | {s['high']} | {s['low']} |"
            )

    high_levels = {k: v for k, v in all_findings.items() if any(x["severity"] == "high" for x in v)}
    lines.extend(
        [
            "",
            f"**Levels with high-severity flags:** {len(high_levels)}",
            "",
            "---",
            "",
        ]
    )

    by_ml: dict[int, list[tuple[str, list[dict]]]] = defaultdict(list)
    for name, hits in sorted(all_findings.items()):
        if not any(h["severity"] == "high" for h in hits):
            continue
        ml = flow_map[name]["mainLevel"]
        by_ml[ml].append((name, hits))

    for ml in sorted(by_ml):
        part = ml_part(ml)
        lines.append(f"## ML{ml} · Part {part} — high-severity")
        lines.append("")
        lines.append(f"*{PART_NAMES[part]}*")
        lines.append("")
        for name, hits in by_ml[ml]:
            title = flow_map[name].get("title", name)
            high = [h for h in hits if h["severity"] == "high"]
            lines.append(f"### {name} — {title} ({len(high)} high)")
            lines.append("")
            lines.append("| Q | Template | Location | Issue | Snippet |")
            lines.append("|---|----------|----------|-------|---------|")
            for h in high:
                snip = h["text"].replace("|", "\\|").replace("\n", " ")
                if len(snip) > 90:
                    snip = snip[:87] + "…"
                lines.append(
                    f"| {h['q']} | {h['template']} | {h['location']} | {h['label']} | `{snip}` |"
                )
            lines.append("")

    # Low-only levels section
    low_only: dict[int, list[str]] = defaultdict(list)
    for name, hits in sorted(all_findings.items()):
        if any(h["severity"] == "high" for h in hits):
            continue
        ml = flow_map[name]["mainLevel"]
        low_only[ml].append(f"{name} ({len(hits)} low)")

    lines.extend(["## Levels with low-severity flags only (mostly distractors)", ""])
    for ml in sorted(low_only):
        lines.append(f"**ML{ml}:** " + ", ".join(low_only[ml]))
    lines.append("")

    # Clean levels
    clean: list[str] = []
    for name, entry in flow_map.items():
        if name in all_findings:
            continue
        qpath = questions_path(name, flavor)
        if qpath.is_file():
            data = json.loads(qpath.read_text(encoding="utf-8"))
            if data.get("levelQuestions"):
                clean.append(f"{name} (ML{entry['mainLevel']})")

    lines.extend(["## No flags", ""])
    lines.extend(clean if clean else ["_None_"])
    lines.append("")

    out_path = OUT if flavor == "adults" else OUT.with_name(
        OUT.stem + f"-{flavor}" + OUT.suffix
    )
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path}")
    print(f"High-level flags: {len(high_levels)}, total hits: {sum(len(v) for v in all_findings.values())}")


if __name__ == "__main__":
    main()
