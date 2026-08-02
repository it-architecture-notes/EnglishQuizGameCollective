#!/usr/bin/env python3
"""Generate per-level quiz audio assets with Gemini TTS.

Development-time only utility:
- Reads questions from
    app/assets/quiz-data/levels/{level_id}/{flavor}/questions.json
  falling back to the level-root questions.json when the flavor folder
  has not been migrated yet.
- Generates .m4a for questions with top-level "audio_file", or for
  DialogueCompletion with "audio_file1" (line1) + "audio_file2" (answer)
- Writes into the flavor folder when present (matches Flutter loaders):
    adults → .../levels/{level_id}/adults/{stem}.m4a
    kids   → .../levels/{level_id}/kids/{stem}.m4a
  If the flavor folder is missing, creates it so clips land where the app
  expects (`image_quiz_screen._audioAssetPathForRaw` / level_config_loader).
- Does NOT modify questions.json

JSON shapes (aligned with app/lib/models/level_config.dart):
- ConvoTemplate-1: `questionData.line1` / `line2` are plain English strings (optional
  legacy `{"en": "..."}` maps are still read for older files).
- ClozeSequence: `questionData.sentence` is a plain English string
  (optional legacy locale map: `en` key used).
- DialogueCompletion: `line1` is a plain English string (legacy
  `{"en": ...}` still read). Optional `english_to_translate` / `local_translation`
  are not used for TTS.
- ConvoTemplate-1: optional split clips — top-level `audio_file1` + `audio_file2`
  (both required together). Spoken text is each line after blanks are filled with
  `answer`, same as the single-file multi-speaker script path.
"""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import shutil
import subprocess
import tempfile
import time
import wave
from collections import deque
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from google import genai
from google.genai import types

MODEL_NAME = "gemini-2.5-flash-preview-tts"
DEFAULT_SINGLE_VOICE = "Puck"
DEFAULT_VOICE_A = "Puck"
DEFAULT_VOICE_B = "Leda"
DEFAULT_BITRATE_KBPS = 96
SUPPORTED_BITRATES = {64, 96}

# Adults defaults (clear adult/teen learner narration).
DEFAULT_ADULTS_MALE_VOICES = ("Puck",)
DEFAULT_ADULTS_FEMALE_VOICES = ("Leda",)
ADULTS_STYLE_PROMPT = 'Say in a clear, friendly tone for a young learner: "{text}"'

# Kids defaults — Gemini 2.5 TTS prebuilt voices that read youthful / playful
# (same 30-voice catalog as 3.1 Flash TTS). Prefer these over Mature / Firm / Gravelly.
# See README "Kids flavor voices".
DEFAULT_KIDS_MALE_VOICES = ("Puck", "Fenrir", "Sadachbia", "Achird")
DEFAULT_KIDS_FEMALE_VOICES = ("Leda", "Laomedeia", "Aoede", "Zephyr", "Autonoe")
KIDS_STYLE_PROMPT = (
    'Say in a young child\'s high-pitched, playful, clear voice: "{text}"'
)

# Gemini TTS output in these examples is PCM 24kHz, 16-bit mono.
PCM_CHANNELS = 1
PCM_SAMPLE_WIDTH_BYTES = 2
PCM_SAMPLE_RATE = 24_000

BLANK_RE = re.compile(r"_{2,}")


@dataclass(frozen=True)
class GenderVoiceContext:
    """Character name pools from conversation_characters.json + Gemini voice lists from env."""

    male_names: frozenset[str]
    female_names: frozenset[str]
    male_voices: tuple[str, ...]
    female_voices: tuple[str, ...]


def _normalize_flavor(raw: str | None) -> str:
    """Return 'kids' or 'adults' (default adults)."""
    v = (raw or "").strip().lower()
    if v in ("kids", "kid", "children", "child"):
        return "kids"
    return "adults"


def _style_prompt_template(flavor: str) -> str:
    """Optional GEMINI_TTS_STYLE_PROMPT overrides the flavor default (must contain {text})."""
    custom = os.getenv("GEMINI_TTS_STYLE_PROMPT", "").strip()
    if custom:
        if "{text}" not in custom:
            raise SystemExit(
                "GEMINI_TTS_STYLE_PROMPT must include the literal placeholder {text}"
            )
        return custom
    return KIDS_STYLE_PROMPT if flavor == "kids" else ADULTS_STYLE_PROMPT


def _format_style_prompt(template: str, text: str) -> str:
    return template.replace("{text}", text)


def _gemini_voice_lists_from_env(flavor: str = "adults") -> tuple[list[str], list[str]]:
    """Resolve male/female Gemini prebuilt voice lists for the active flavor.

    Adults: GEMINI_TTS_MALE_VOICES / GEMINI_TTS_FEMALE_VOICES, else adults defaults.
    Kids: GEMINI_TTS_KIDS_MALE_VOICES / GEMINI_TTS_KIDS_FEMALE_VOICES, else kids
    defaults (does not inherit the adults env lists, so a shared .env stays safe).
    """
    if flavor == "kids":
        male = _parse_voice_list(os.getenv("GEMINI_TTS_KIDS_MALE_VOICES", ""))
        female = _parse_voice_list(os.getenv("GEMINI_TTS_KIDS_FEMALE_VOICES", ""))
        if not male:
            male = list(DEFAULT_KIDS_MALE_VOICES)
        if not female:
            female = list(DEFAULT_KIDS_FEMALE_VOICES)
        return male, female

    male = _parse_voice_list(os.getenv("GEMINI_TTS_MALE_VOICES", ""))
    female = _parse_voice_list(os.getenv("GEMINI_TTS_FEMALE_VOICES", ""))
    if not male:
        male = list(DEFAULT_ADULTS_MALE_VOICES)
    if not female:
        female = list(DEFAULT_ADULTS_FEMALE_VOICES)
    return male, female


def load_gender_voice_context(
    repo_root: Path, flavor: str = "adults"
) -> GenderVoiceContext:
    """Load character name pools and env male/female Gemini voice lists."""
    path = (
        repo_root
        / "app"
        / "assets"
        / "data"
        / "config"
        / "conversation_characters.json"
    )
    male_set: set[str] = set()
    female_set: set[str] = set()
    if path.is_file():
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
            # v2 schema: characterNamePools.en.{male,female} (locale-keyed pools
            # alongside "en"). Authored character1/character2 in questions.json
            # are always the English name, so gender lookup always uses "en".
            pools = ((raw.get("characterNamePools") or {}).get("en")) or {}
            male_set = {
                str(x).strip().lower()
                for x in (pools.get("male") or [])
                if str(x).strip()
            }
            female_set = {
                str(x).strip().lower()
                for x in (pools.get("female") or [])
                if str(x).strip()
            }
        except (OSError, json.JSONDecodeError, TypeError, AttributeError):
            pass
    m_voices, f_voices = _gemini_voice_lists_from_env(flavor)
    return GenderVoiceContext(
        male_names=frozenset(male_set),
        female_names=frozenset(female_set),
        male_voices=tuple(m_voices),
        female_voices=tuple(f_voices),
    )


def _gender_for_character(slug: str, ctx: GenderVoiceContext) -> str | None:
    """Return 'male' / 'female' if the slug matches a pool name, else None."""
    key = (slug or "").strip().lower()
    if key in ctx.male_names:
        return "male"
    if key in ctx.female_names:
        return "female"
    return None


def _random_gemini_voice_any_gender(ctx: GenderVoiceContext) -> str:
    """Random prebuilt voice from combined male + female env lists."""
    combined = list(ctx.male_voices) + list(ctx.female_voices)
    return random.choice(combined)


def _gemini_voice_excluding(pool: tuple[str, ...], exclude: str | None) -> str:
    """Pick a random voice from pool, avoiding exclude when the pool has more than one option."""
    if exclude and len(pool) > 1:
        candidates = [v for v in pool if v != exclude]
        return random.choice(candidates)
    return random.choice(pool)


def _gender_from_audio_filename(stem: str) -> str | None:
    """Return 'male' or 'female' if those words appear as dash-separated tokens in the stem.

    Checks 'female' before 'male' so that a stem containing 'female' is not
    misidentified as 'male' (since 'female' contains the substring 'male').
    """
    tokens = {t.lower() for t in stem.replace("_", "-").split("-") if t}
    if "female" in tokens:
        return "female"
    if "male" in tokens:
        return "male"
    return None


def _gender_from_genders_field(row: dict[str, Any], slot: int) -> str | None:
    """Reads the row's mandatory top-level "genders" casting code (e.g. "f-m",
    or "m"/"f" for single-person templates — see validate_quiz_level_json.py).

    slot 0 = character1 (or the sole slot for single-person templates),
    slot 1 = character2. This is the authoritative casting signal once
    character1/character2 are blank (most rows now — see
    ConversationCharacterPool on the Dart side, which reads the same field).
    """
    raw = str(row.get("genders") or "").strip().lower()
    if not raw:
        return None
    parts = raw.split("-")
    code = parts[slot] if slot < len(parts) else (parts[0] if parts else None)
    if code == "m":
        return "male"
    if code == "f":
        return "female"
    return None


def _gemini_voice_for_gender(gender: str | None, ctx: GenderVoiceContext) -> str | None:
    """Return a random voice from the matching gender pool, or None if undetermined."""
    if gender == "female" and ctx.female_voices:
        return random.choice(ctx.female_voices)
    if gender == "male" and ctx.male_voices:
        return random.choice(ctx.male_voices)
    return None


def _parse_voice_list(env_val: str | None) -> list[str]:
    """Comma-separated voice names or IDs (trimmed, empty segments dropped)."""
    if not env_val or not str(env_val).strip():
        return []
    return [x.strip() for x in str(env_val).split(",") if x.strip()]


def _env_truthy(name: str) -> bool:
    v = os.getenv(name, "").strip().lower()
    return v in ("1", "true", "yes", "on")


def configure_tts_voices(args: argparse.Namespace) -> None:
    """Resolve Gemini voice defaults from CLI and env (male/female voice lists)."""
    flavor = getattr(args, "flavor", "adults")
    mlist, flist = _gemini_voice_lists_from_env(flavor)

    g_voice = args.voice if args.voice is not None else mlist[0]
    g_a = args.voice_a if args.voice_a is not None else mlist[0]
    g_b = args.voice_b if args.voice_b is not None else (flist[0] if flist else mlist[0])

    args.voice = g_voice
    args.voice_a = g_a
    args.voice_b = g_b

    pool = mlist + flist
    args._gemini_single_voice_pool = pool
    args._gemini_rotate_single = _env_truthy("GEMINI_TTS_VOICE_ROTATE")
    args._style_prompt_template = _style_prompt_template(flavor)


@dataclass(frozen=True)
class CandidateJob:
    question_index: int
    template: str
    audio_file_value: str
    output_filename: str
    output_path: Path
    tts_text: str | None
    speaker_mode: str  # "single" | "multi" | "skip"
    speaker_a_name: str | None = None
    speaker_b_name: str | None = None
    reason: str | None = None
    gemini_voice_override: str | None = None
    gemini_multi_voice_a: str | None = None
    gemini_multi_voice_b: str | None = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate Gemini TTS .m4a files for one level."
    )
    parser.add_argument("--level-id", required=True, help="Level folder name")
    parser.add_argument(
        "--workspace-root",
        default=None,
        help="Repo root path (defaults to script-relative root)",
    )
    parser.add_argument(
        "--flavor",
        default=None,
        choices=["kids", "adults"],
        help=(
            "App flavor: kids uses playful child-style prompts + youthful voice "
            "defaults and writes under levels/{level}/kids/ "
            "(default: GEMINI_TTS_FLAVOR or adults)"
        ),
    )
    parser.add_argument(
        "--voice",
        default=None,
        metavar="NAME",
        help=(
            "Gemini single-speaker voice (default: first entry in GEMINI_TTS_MALE_VOICES)"
        ),
    )
    parser.add_argument(
        "--voice-a",
        default=None,
        metavar="NAME",
        help=(
            "Gemini multi-speaker voice A (default: first GEMINI_TTS_MALE_VOICES)"
        ),
    )
    parser.add_argument(
        "--voice-b",
        default=None,
        metavar="NAME",
        help=(
            "Gemini multi-speaker voice B (default: first GEMINI_TTS_FEMALE_VOICES)"
        ),
    )
    parser.add_argument(
        "--output-suffix",
        default=None,
        help=(
            "Suffix added to output filename before .m4a "
            "(default: empty — flavor is the kids/ or adults/ folder)"
        ),
    )
    parser.add_argument(
        "--bitrate",
        type=int,
        default=DEFAULT_BITRATE_KBPS,
        choices=sorted(SUPPORTED_BITRATES),
        help="M4A bitrate in kbps",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview generation without API calls or file writes",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite existing output files",
    )
    parser.add_argument(
        "--question",
        type=int,
        default=None,
        help="Only process one question index (0-based)",
    )
    return parser.parse_args()


def resolve_paths(args: argparse.Namespace) -> tuple[Path, Path, Path]:
    """Return (repo_root, questions_path, level_dir).

    Prefer `{level}/{flavor}/questions.json`, then level-root `questions.json`.
    `level_dir` is always the level root (never the flavor subfolder).
    """
    if args.workspace_root:
        repo_root = Path(args.workspace_root).expanduser().resolve()
    else:
        # tools/gemini_tts/generate_level_audio.py -> repo root is parents[2]
        repo_root = Path(__file__).resolve().parents[2]
    level_dir = (
        repo_root / "app" / "assets" / "quiz-data" / "levels" / args.level_id
    ).resolve()
    flavor = getattr(args, "flavor", "adults")
    flavor_questions = level_dir / flavor / "questions.json"
    root_questions = level_dir / "questions.json"
    if flavor_questions.is_file():
        questions_path = flavor_questions
    else:
        questions_path = root_questions
    return repo_root, questions_path, level_dir


def resolve_flavor_audio_dir(level_dir: Path, flavor: str) -> tuple[Path, bool]:
    """Return (output_dir, created) for clips of this flavor.

    Prefer existing `level_dir/{flavor}/` (kids or adults). If missing, create
    it so generated voices match Flutter path
    `quiz-data/levels/{level}/{flavor}/{stem}.m4a`.
    """
    flavor_dir = (level_dir / flavor).resolve()
    created = False
    if not flavor_dir.is_dir():
        flavor_dir.mkdir(parents=True, exist_ok=True)
        created = True
    return flavor_dir, created


def resolve_output_suffix(output_suffix_arg: str | None) -> str:
    """Explicit --output-suffix, else empty (folder carries the flavor)."""
    if output_suffix_arg is not None:
        return output_suffix_arg
    return ""


def resolve_level_audio_output(
    output_dir: Path, stem: str, output_suffix: str = ""
) -> tuple[str, Path]:
    """Filename + absolute path under the flavor (or output) directory.

    Matches Flutter `_audioAssetPathForRaw`:
      adults → levels/{level}/adults/{stem}.m4a
      kids   → levels/{level}/kids/{stem}.m4a
    """
    base = stem.strip()
    if base.lower().endswith(".m4a"):
        base = base[:-4]
    # Strip a legacy trailing -kids if present (folder already encodes flavor).
    if base.endswith("-kids"):
        base = base[: -len("-kids")]
    output_filename = f"{base}{output_suffix}.m4a"
    output_path = output_dir.resolve() / output_filename
    return output_filename, output_path


def _job_for_stem(
    idx: int,
    template: str,
    output_dir: Path,
    stem: str,
    output_suffix: str,
    tts_text: str,
    speaker_mode: str,
    speaker_a_name: str | None = None,
    speaker_b_name: str | None = None,
    gemini_voice_override: str | None = None,
) -> CandidateJob:
    output_filename, output_path = resolve_level_audio_output(
        output_dir, stem, output_suffix
    )
    return CandidateJob(
        question_index=idx,
        template=template,
        audio_file_value=stem,
        output_filename=output_filename,
        output_path=output_path,
        tts_text=tts_text,
        speaker_mode=speaker_mode,
        speaker_a_name=speaker_a_name,
        speaker_b_name=speaker_b_name,
        gemini_voice_override=gemini_voice_override,
    )


def _str_or_none(value: Any) -> str | None:
    if isinstance(value, str):
        v = value.strip()
        return v if v else None
    return None


def _localized_en(value: Any) -> str | None:
    if isinstance(value, str):
        return _str_or_none(value)
    if isinstance(value, dict):
        return _str_or_none(value.get("en"))
    return None


def _replace_blanks_with_blank(text: str) -> str:
    # TTS: spoken pause only (no literal "Blank"); use for ___ / _____ gaps.
    # Example: "I _____ tea" -> "I [long pause] tea"
    replaced = BLANK_RE.sub(" [long pause] ", text)
    # Normalize spacing around punctuation.
    replaced = re.sub(r"\s+([,.;!?])", r"\1", replaced)
    replaced = re.sub(r"\s+", " ", replaced).strip()
    # Sentence-final gap only (e.g. "My name is _____"): TTS may speak "Blank" after a
    # trailing "[long pause]" — end on the last word.
    replaced = re.sub(r"\s*\[long pause\]\s*$", "", replaced).strip()
    return replaced


def _replace_blanks_with_answer(text: str, answer: str | None) -> str:
    if answer and answer.strip():
        return BLANK_RE.sub(answer.strip(), text)
    return _replace_blanks_with_blank(text)


def _normalize_spoken_line(text: str) -> str:
    """Collapse whitespace; no space before punctuation."""
    t = re.sub(r"\s+", " ", text).strip()
    t = re.sub(r"\s+([,.;!?])", r"\1", t)
    return t


def _cloze_answers_list(qd: dict[str, Any]) -> list[str]:
    raw = qd.get("answer") or qd.get("answers")
    if isinstance(raw, list):
        return [str(x).strip() for x in raw if str(x).strip()]
    if isinstance(raw, str):
        return [raw.strip()] if raw.strip() else []
    return []


def _replace_blanks_sequential(text: str, answers: list[str]) -> str:
    out = text
    for ans in answers:
        if not BLANK_RE.search(out):
            break
        out = BLANK_RE.sub(ans, out, count=1)
    return out


def _cloze_sequence_tts_text(sentence_en: str, qd: dict[str, Any]) -> str:
    """Fill ClozeSequence `sentence` blanks with `answer` / `answers` (in order)."""
    answers = _cloze_answers_list(qd)
    text = _replace_blanks_sequential(sentence_en, answers)
    if BLANK_RE.search(text):
        text = _replace_blanks_with_blank(text)
    else:
        text = re.sub(r"\s+", " ", text).strip()
        text = re.sub(r"\s+([,.;!?])", r"\1", text)
    return text


def _words_list(value: Any) -> list[str]:
    if isinstance(value, str):
        return [x for x in value.strip().split() if x]
    if not isinstance(value, list):
        return []
    return [str(x).strip() for x in value if str(x).strip()]


def _join_words(value: Any) -> str | None:
    out = _words_list(value)
    return " ".join(out) if out else None


def build_jobs_for_question(
    level_id: str,
    output_dir: Path,
    q: dict[str, Any],
    idx: int,
    output_suffix: str,
    gender_ctx: GenderVoiceContext | None = None,
) -> list[CandidateJob]:
    """Returns one or more TTS jobs for a single levelQuestions row."""
    template = str(q.get("template", "")).strip()
    audio_file = _str_or_none(q.get("audio_file")) or ""
    af1 = _str_or_none(q.get("audio_file1"))
    af2 = _str_or_none(q.get("audio_file2"))

    # DialogueCompletion: always two clips — line1, then answer (with blanks filled).
    if template == "DialogueCompletion":
        qd = q.get("questionData")
        if not isinstance(qd, dict):
            return [
                CandidateJob(
                    question_index=idx,
                    template=template,
                    audio_file_value="",
                    output_filename=f"_invalid{output_suffix}.m4a",
                    output_path=output_dir / f"_invalid{output_suffix}.m4a",
                    tts_text=None,
                    speaker_mode="skip",
                    reason="missing_question_data",
                )
            ]
        if not af1 or not af2:
            return [
                CandidateJob(
                    question_index=idx,
                    template=template,
                    audio_file_value="",
                    output_filename=f"_invalid{output_suffix}.m4a",
                    output_path=output_dir / f"_invalid{output_suffix}.m4a",
                    tts_text=None,
                    speaker_mode="skip",
                    reason="dialogue_completion_requires_audio_file1_and_audio_file2",
                )
            ]
        line1 = _localized_en(qd.get("line1"))
        answer = _str_or_none(qd.get("answer"))
        if not line1 or not answer:
            return [
                CandidateJob(
                    question_index=idx,
                    template=template,
                    audio_file_value="",
                    output_filename=f"_invalid{output_suffix}.m4a",
                    output_path=output_dir / f"_invalid{output_suffix}.m4a",
                    tts_text=None,
                    speaker_mode="skip",
                    reason="dual_dialogue_missing_line1_or_answer",
                )
            ]
        text_answer = _replace_blanks_with_blank(answer)
        c1 = _str_or_none(qd.get("character1"))
        c2 = _str_or_none(qd.get("character2"))
        # Precedence: authored character name -> row's "genders" field -> unknown.
        if gender_ctx is not None:
            gender1 = (_gender_for_character(c1, gender_ctx) if c1 else None) or (
                _gender_from_genders_field(q, 0)
            )
            gender2 = (_gender_for_character(c2, gender_ctx) if c2 else None) or (
                _gender_from_genders_field(q, 1)
            )
            v1 = _gemini_voice_for_gender(gender1, gender_ctx) or _random_gemini_voice_any_gender(
                gender_ctx
            )
            pool2 = (
                gender_ctx.female_voices if gender2 == "female"
                else gender_ctx.male_voices if gender2 == "male"
                else tuple(list(gender_ctx.male_voices) + list(gender_ctx.female_voices))
            )
            v2 = _gemini_voice_excluding(pool2, v1)
        else:
            v1 = None
            v2 = None
        # Filename gender hint overrides character/genders-based voice for each clip.
        if gender_ctx is not None:
            g1 = _gender_from_audio_filename(af1)
            g2 = _gender_from_audio_filename(af2)
            v1 = _gemini_voice_for_gender(g1, gender_ctx) or v1
            v2 = _gemini_voice_for_gender(g2, gender_ctx) or v2
        # Optional top-level text overrides for each clip.
        text1 = _str_or_none(q.get("audio_file1_text")) or line1
        text2 = _str_or_none(q.get("audio_file2_text")) or text_answer
        return [
            _job_for_stem(
                idx,
                template,
                output_dir,
                af1,
                output_suffix,
                text1,
                "single",
                gemini_voice_override=v1,
            ),
            _job_for_stem(
                idx,
                template,
                output_dir,
                af2,
                output_suffix,
                text2,
                "single",
                gemini_voice_override=v2,
            ),
        ]

    # ConvoTemplate-1: two single-speaker clips (line1 / line2, blanks filled with answer).
    if template == "ConvoTemplate-1" and af1 and af2:
        qd = q.get("questionData")
        if not isinstance(qd, dict):
            return [
                CandidateJob(
                    question_index=idx,
                    template=template,
                    audio_file_value="",
                    output_filename=f"_invalid{output_suffix}.m4a",
                    output_path=output_dir / f"_invalid{output_suffix}.m4a",
                    tts_text=None,
                    speaker_mode="skip",
                    reason="missing_question_data",
                )
            ]
        line1 = _localized_en(qd.get("line1"))
        line2 = _localized_en(qd.get("line2"))
        answer = _str_or_none(qd.get("answer"))
        if not line1 or not line2 or not answer:
            return [
                CandidateJob(
                    question_index=idx,
                    template=template,
                    audio_file_value="",
                    output_filename=f"_invalid{output_suffix}.m4a",
                    output_path=output_dir / f"_invalid{output_suffix}.m4a",
                    tts_text=None,
                    speaker_mode="skip",
                    reason="convo1_dual_missing_line1_line2_or_answer",
                )
            ]
        line1_resolved = _normalize_spoken_line(
            _replace_blanks_with_answer(line1, answer)
        )
        line2_resolved = _normalize_spoken_line(
            _replace_blanks_with_answer(line2, answer)
        )
        c1 = _str_or_none(qd.get("character1"))
        c2 = _str_or_none(qd.get("character2"))
        # Precedence: authored character name -> row's "genders" field -> unknown.
        if gender_ctx is not None:
            gender1 = (_gender_for_character(c1, gender_ctx) if c1 else None) or (
                _gender_from_genders_field(q, 0)
            )
            gender2 = (_gender_for_character(c2, gender_ctx) if c2 else None) or (
                _gender_from_genders_field(q, 1)
            )
            v1 = _gemini_voice_for_gender(gender1, gender_ctx) or _random_gemini_voice_any_gender(
                gender_ctx
            )
            pool2 = (
                gender_ctx.female_voices if gender2 == "female"
                else gender_ctx.male_voices if gender2 == "male"
                else tuple(list(gender_ctx.male_voices) + list(gender_ctx.female_voices))
            )
            v2 = _gemini_voice_excluding(pool2, v1)
        else:
            v1 = None
            v2 = None
        if gender_ctx is not None:
            g1 = _gender_from_audio_filename(af1)
            g2 = _gender_from_audio_filename(af2)
            v1 = _gemini_voice_for_gender(g1, gender_ctx) or v1
            v2 = _gemini_voice_for_gender(g2, gender_ctx) or v2
        text1 = _str_or_none(q.get("audio_file1_text")) or line1_resolved
        text2 = _str_or_none(q.get("audio_file2_text")) or line2_resolved
        return [
            _job_for_stem(
                idx,
                template,
                output_dir,
                af1,
                output_suffix,
                text1,
                "single",
                gemini_voice_override=v1,
            ),
            _job_for_stem(
                idx,
                template,
                output_dir,
                af2,
                output_suffix,
                text2,
                "single",
                gemini_voice_override=v2,
            ),
        ]

    job = build_job(level_id, output_dir, q, idx, output_suffix, gender_ctx)
    override_text = _str_or_none(q.get("audio_file_text"))
    if override_text and job.speaker_mode != "skip":
        job = replace(job, tts_text=override_text)
    return [job]


def build_job(
    level_id: str,
    output_dir: Path,
    q: dict[str, Any],
    idx: int,
    output_suffix: str,
    gender_ctx: GenderVoiceContext | None = None,
) -> CandidateJob:
    template = str(q.get("template", "")).strip()
    audio_file_value = _str_or_none(q.get("audio_file")) or ""
    output_filename, output_path = resolve_level_audio_output(
        output_dir,
        audio_file_value if audio_file_value else "_missing",
        output_suffix,
    )

    # Derive a gender-specific voice override, filename token taking precedence
    # over the row's "genders" field (single-person templates use slot 0 —
    # AppearDisappear/ClozeSequence/SentenceBuilder never have character1/2).
    _filename_gender = _gender_from_audio_filename(audio_file_value)
    _genders_field_gender = _gender_from_genders_field(q, 0)
    _resolved_single_gender = _filename_gender or _genders_field_gender
    _filename_voice: str | None = (
        _gemini_voice_for_gender(_resolved_single_gender, gender_ctx)
        if gender_ctx is not None and _resolved_single_gender is not None
        else None
    )

    if not audio_file_value:
        return CandidateJob(
            question_index=idx,
            template=template,
            audio_file_value=audio_file_value,
            output_filename=output_filename,
            output_path=output_path,
            tts_text=None,
            speaker_mode="skip",
            reason="missing_audio_file",
        )

    qd = q.get("questionData")
    if not isinstance(qd, dict):
        return CandidateJob(
            question_index=idx,
            template=template,
            audio_file_value=audio_file_value,
            output_filename=output_filename,
            output_path=output_path,
            tts_text=None,
            speaker_mode="skip",
            reason="missing_question_data",
        )

    # ConvoTemplate-1: multi-speaker
    if template == "ConvoTemplate-1":
        line1 = _localized_en(qd.get("line1"))
        line2 = _localized_en(qd.get("line2"))
        if not line1 or not line2:
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=None,
                speaker_mode="skip",
                reason="missing_line1_or_line2",
            )
        answer = _str_or_none(qd.get("answer"))
        line1_resolved = _normalize_spoken_line(
            _replace_blanks_with_answer(line1, answer)
        )
        line2_resolved = _normalize_spoken_line(
            _replace_blanks_with_answer(line2, answer)
        )
        char1_name = _str_or_none(qd.get("character1"))
        char2_name = _str_or_none(qd.get("character2"))
        char1 = char1_name or "SpeakerA"
        char2 = char2_name or "SpeakerB"
        text = f"{char1}: {line1_resolved}\n{char2}: {line2_resolved}"
        # Precedence: authored character name -> row's "genders" field -> unknown.
        if gender_ctx is not None:
            gender1 = (
                _gender_for_character(char1_name, gender_ctx) if char1_name else None
            ) or _gender_from_genders_field(q, 0)
            gender2 = (
                _gender_for_character(char2_name, gender_ctx) if char2_name else None
            ) or _gender_from_genders_field(q, 1)
            mva = _gemini_voice_for_gender(gender1, gender_ctx) or _random_gemini_voice_any_gender(
                gender_ctx
            )
            pool2 = (
                gender_ctx.female_voices if gender2 == "female"
                else gender_ctx.male_voices if gender2 == "male"
                else tuple(list(gender_ctx.male_voices) + list(gender_ctx.female_voices))
            )
            mvb = _gemini_voice_excluding(pool2, mva)
        else:
            mva = None
            mvb = None
        return CandidateJob(
            question_index=idx,
            template=template,
            audio_file_value=audio_file_value,
            output_filename=output_filename,
            output_path=output_path,
            tts_text=text,
            speaker_mode="multi",
            speaker_a_name=char1,
            speaker_b_name=char2,
            gemini_multi_voice_a=mva,
            gemini_multi_voice_b=mvb,
        )

    if template == "AppearDisappear":
        words = _words_list(qd.get("words"))
        if words:
            text = " ".join(words)
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
                gemini_voice_override=_filename_voice,
            )

    if template == "GrammarForm":
        return CandidateJob(
            question_index=idx,
            template=template,
            audio_file_value=audio_file_value,
            output_filename=output_filename,
            output_path=output_path,
            tts_text=None,
            speaker_mode="skip",
            reason="grammar_no_audio",
        )

    if template == "ClozeSequence":
        sentence_en = _localized_en(qd.get("sentence"))
        if sentence_en:
            text = _cloze_sequence_tts_text(sentence_en, qd)
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
                gemini_voice_override=_filename_voice,
            )

    if template == "SentenceBuilder":
        text = _join_words(qd.get("correct_order"))
        if text:
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
                gemini_voice_override=_filename_voice,
            )

    if template == "imageQuizTemplate-2":
        answer = _str_or_none(qd.get("answer"))
        text = answer
        if text:
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
                gemini_voice_override=_filename_voice,
            )

    return CandidateJob(
        question_index=idx,
        template=template,
        audio_file_value=audio_file_value,
        output_filename=output_filename,
        output_path=output_path,
        tts_text=None,
        speaker_mode="skip",
        reason="unsupported_or_missing_text",
    )


def parse_questions(questions_path: Path) -> list[dict[str, Any]]:
    raw = json.loads(questions_path.read_text(encoding="utf-8"))
    rows = raw.get("levelQuestions")
    if not isinstance(rows, list):
        raise ValueError(f"Invalid JSON: {questions_path} missing levelQuestions[]")
    out: list[dict[str, Any]] = []
    for row in rows:
        if isinstance(row, dict):
            out.append(row)
    return out


def extract_pcm_bytes(response: Any) -> bytes:
    candidates = getattr(response, "candidates", None) or []
    for candidate in candidates:
        content = getattr(candidate, "content", None)
        if not content:
            continue
        for part in getattr(content, "parts", []) or []:
            inline_data = getattr(part, "inline_data", None)
            if inline_data and getattr(inline_data, "data", None):
                return inline_data.data
    raise RuntimeError("No inline audio data found in Gemini response")


class _RateLimiter:
    """Sliding-window rate limiter: at most max_calls API requests per period_seconds."""

    def __init__(self, max_calls: int = 10, period_seconds: float = 60.0) -> None:
        self._max = max_calls
        self._period = period_seconds
        self._timestamps: deque[float] = deque()

    def wait(self) -> None:
        """Block until a request slot is available, then claim it."""
        while True:
            now = time.time()
            while self._timestamps and now - self._timestamps[0] >= self._period:
                self._timestamps.popleft()
            if len(self._timestamps) < self._max:
                self._timestamps.append(now)
                return
            wait_s = self._period - (now - self._timestamps[0]) + 0.5
            print(f"  [rate limit] {len(self._timestamps)}/{self._max} calls in window — waiting {wait_s:.1f}s")
            time.sleep(wait_s)


def _retry_call(fn, attempts: int = 3, base_delay_s: float = 1.0) -> Any:
    last_exc: Exception | None = None
    for i in range(attempts):
        try:
            return fn()
        except Exception as exc:  # noqa: BLE001
            last_exc = exc
            if i == attempts - 1:
                break
            time.sleep(base_delay_s * (2**i))
    assert last_exc is not None
    raise last_exc


def _silence_pcm(duration_ms: int = 300) -> bytes:
    """Return raw PCM bytes for silence at the script's standard sample rate."""
    num_samples = int(PCM_SAMPLE_RATE * duration_ms / 1000)
    return b"\x00\x00" * num_samples  # 16-bit mono silence


def generate_single_speaker_pcm(
    client: genai.Client,
    text: str,
    voice: str,
    rate_limiter: _RateLimiter | None = None,
    style_prompt_template: str = ADULTS_STYLE_PROMPT,
) -> bytes:
    def _call() -> Any:
        if rate_limiter is not None:
            rate_limiter.wait()
        return client.models.generate_content(
            model=MODEL_NAME,
            contents=_format_style_prompt(style_prompt_template, text),
            config=types.GenerateContentConfig(
                response_modalities=["AUDIO"],
                speech_config=types.SpeechConfig(
                    voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(
                            voice_name=voice
                        )
                    )
                ),
            ),
        )

    response = _retry_call(_call)
    return extract_pcm_bytes(response)


def pcm_to_m4a_file(pcm_bytes: bytes, output_path: Path, bitrate_kbps: int) -> None:
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_wav_path = Path(tmp.name)
    try:
        with wave.open(str(tmp_wav_path), "wb") as wf:
            wf.setnchannels(PCM_CHANNELS)
            wf.setsampwidth(PCM_SAMPLE_WIDTH_BYTES)
            wf.setframerate(PCM_SAMPLE_RATE)
            wf.writeframes(pcm_bytes)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                str(tmp_wav_path),
                "-c:a",
                "aac",
                "-b:a",
                f"{bitrate_kbps}k",
                str(output_path),
            ],
            check=True,
        )
    finally:
        if tmp_wav_path.exists():
            tmp_wav_path.unlink(missing_ok=True)


def ensure_ffmpeg_available() -> None:
    if shutil.which("ffmpeg") is None:
        raise SystemExit(
            "ffmpeg is required for M4A conversion but was not found on PATH."
        )


def main() -> None:
    args = parse_args()
    flavor_from_cli = args.flavor is not None

    # Load .env before resolving flavor / voice lists from the environment.
    load_dotenv()

    # Flavor: CLI > GEMINI_TTS_FLAVOR > adults
    if flavor_from_cli:
        args.flavor = _normalize_flavor(args.flavor)
    else:
        args.flavor = _normalize_flavor(os.getenv("GEMINI_TTS_FLAVOR", "adults"))

    repo_root, questions_path, level_dir = resolve_paths(args)
    if not questions_path.is_file():
        raise SystemExit(
            f"questions.json not found for flavor={args.flavor!r}. "
            f"Tried {level_dir / args.flavor / 'questions.json'} "
            f"and {level_dir / 'questions.json'}"
        )

    explicit_gemini_voice = args.voice is not None
    configure_tts_voices(args)

    google_api_key = os.getenv("GOOGLE_API_KEY", "").strip()
    if not args.dry_run and not google_api_key:
        raise SystemExit("GOOGLE_API_KEY is missing.")

    output_suffix = resolve_output_suffix(args.output_suffix)
    output_dir, flavor_dir_created = resolve_flavor_audio_dir(
        level_dir, args.flavor
    )

    rows = parse_questions(questions_path)
    ensure_ffmpeg_available()

    gender_ctx = load_gender_voice_context(repo_root, args.flavor)
    style_prompt_template = getattr(
        args, "_style_prompt_template", _style_prompt_template(args.flavor)
    )

    jobs: list[CandidateJob] = []
    for idx, q in enumerate(rows):
        if args.question is not None and idx != args.question:
            continue
        jobs.extend(
            build_jobs_for_question(
                args.level_id, output_dir, q, idx, output_suffix, gender_ctx
            )
        )

    # Single-speaker clips without character-based routing: random voice from male+female pool.
    # (Character-routed jobs already set gemini_voice_override; respect --voice and rotation.)
    if (
        not explicit_gemini_voice
        and not getattr(args, "_gemini_rotate_single", False)
    ):
        pool = getattr(args, "_gemini_single_voice_pool", None) or []
        if pool:
            jobs = [
                replace(job, gemini_voice_override=random.choice(pool))
                if job.speaker_mode == "single" and job.gemini_voice_override is None
                else job
                for job in jobs
            ]

    print(f"Repo root: {repo_root}")
    print(f"Level: {args.level_id}")
    print(f"Flavor: {args.flavor}")
    print(f"Questions file: {questions_path}")
    print(f"Level directory: {level_dir}")
    print(f"Output directory: {output_dir}")
    if flavor_dir_created:
        print(f"  (created missing flavor folder: {output_dir})")
    print(
        f"Output naming: {args.flavor}/{{stem}}{output_suffix}.m4a "
        f"(kids → kids/, adults → adults/)"
    )
    print(f"Style prompt: {style_prompt_template}")
    print(f"Candidate rows considered: {len(jobs)}")
    print(
        f"Gemini male voices: {list(gender_ctx.male_voices)}  "
        f"female voices: {list(gender_ctx.female_voices)}"
    )
    print(
        f"Gemini voices: single={args.voice}  A={args.voice_a}  B={args.voice_b}"
    )
    if getattr(args, "_gemini_rotate_single", False):
        print(
            f"  single-speaker rotation pool: "
            f"{getattr(args, '_gemini_single_voice_pool', [])}"
        )

    generated = 0
    skipped_no_audio_file = 0
    skipped_unsupported_template = 0
    skipped_existing = 0
    failed = 0

    client = None
    rate_limiter: _RateLimiter | None = None
    if not args.dry_run:
        client = genai.Client(api_key=google_api_key)
        rate_limiter = _RateLimiter(max_calls=10, period_seconds=60.0)

    gemini_single_ctr = 0

    for job in jobs:
        prefix = f"[q{job.question_index} {job.template}]"
        if job.reason == "missing_audio_file":
            skipped_no_audio_file += 1
            print(f"{prefix} SKIP missing audio_file")
            continue
        if job.speaker_mode == "skip" or not job.tts_text:
            skipped_unsupported_template += 1
            reason = job.reason or "unsupported"
            print(f"{prefix} SKIP {reason}")
            continue

        if job.output_path.exists() and not args.overwrite:
            skipped_existing += 1
            print(f"{prefix} SKIP existing {job.output_filename}")
            continue

        if args.dry_run:
            print(
                f"{prefix} DRY-RUN mode={job.speaker_mode} -> {job.output_path}"
            )
            print(f"  text: {job.tts_text}")
            print(
                f"  style: {_format_style_prompt(style_prompt_template, job.tts_text)}"
            )
            if job.speaker_mode == "multi":
                va = job.gemini_multi_voice_a or args.voice_a
                vb = job.gemini_multi_voice_b or args.voice_b
                print(f"  gemini_voices: A={va} B={vb} (2x single-speaker + merge)")
            elif job.gemini_voice_override:
                print(f"  gemini_voice: {job.gemini_voice_override}")
            generated += 1
            continue

        try:
            assert client is not None
            if job.speaker_mode == "multi":
                va = job.gemini_multi_voice_a or args.voice_a
                vb = job.gemini_multi_voice_b or args.voice_b
                lines = job.tts_text.splitlines()
                line_a = lines[0] if lines else job.tts_text
                line_b = lines[1] if len(lines) > 1 else ""
                line_a = line_a.split(":", 1)[-1].strip() if ":" in line_a else line_a
                line_b = line_b.split(":", 1)[-1].strip() if ":" in line_b else line_b
                pcm_a = generate_single_speaker_pcm(
                    client=client,
                    text=line_a,
                    voice=va,
                    rate_limiter=rate_limiter,
                    style_prompt_template=style_prompt_template,
                )
                pcm_b = generate_single_speaker_pcm(
                    client=client,
                    text=line_b,
                    voice=vb,
                    rate_limiter=rate_limiter,
                    style_prompt_template=style_prompt_template,
                )
                pcm_bytes = pcm_a + _silence_pcm(300) + pcm_b
                pcm_to_m4a_file(
                    pcm_bytes=pcm_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            else:
                voice_use = job.gemini_voice_override
                if voice_use is None:
                    voice_use = args.voice
                    if getattr(args, "_gemini_rotate_single", False):
                        pool = getattr(args, "_gemini_single_voice_pool", None) or []
                        if pool:
                            voice_use = pool[gemini_single_ctr % len(pool)]
                            gemini_single_ctr += 1
                pcm_bytes = generate_single_speaker_pcm(
                    client=client,
                    text=job.tts_text,
                    voice=voice_use,
                    rate_limiter=rate_limiter,
                    style_prompt_template=style_prompt_template,
                )
                pcm_to_m4a_file(
                    pcm_bytes=pcm_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            generated += 1
            print(f"{prefix} OK wrote {job.output_path}")
        except Exception as exc:  # noqa: BLE001
            failed += 1
            print(f"{prefix} FAIL {exc}")

    print("\nSummary:")
    print(f"  generated: {generated}")
    print(f"  skipped_no_audio_file: {skipped_no_audio_file}")
    print(f"  skipped_unsupported_template: {skipped_unsupported_template}")
    print(f"  skipped_existing: {skipped_existing}")
    print(f"  failed: {failed}")


if __name__ == "__main__":
    main()
