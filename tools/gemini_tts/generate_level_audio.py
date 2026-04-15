#!/usr/bin/env python3
"""Generate per-level quiz audio assets with Gemini TTS.

Development-time only utility:
- Reads app/assets/quiz-data/levels/{level_id}/questions.json
- Generates .m4a for questions with top-level "audio_file", or for
  ConvoTemplate-DialogueCompletion with "audio_file1" (line1) + "audio_file2" (answer)
- Writes output files into the same level folder
- Does NOT modify questions.json
"""

from __future__ import annotations

import argparse
import io
import json
import os
import random
import re
import shutil
import subprocess
import tempfile
import time
import wave
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from google import genai
from google.genai import types
import requests

MODEL_NAME = "gemini-2.5-flash-preview-tts"
ELEVENLABS_DEFAULT_MODEL = "eleven_flash_v2_5"
DEFAULT_SINGLE_VOICE = "Puck"
DEFAULT_VOICE_A = "Puck"
DEFAULT_VOICE_B = "Leda"
DEFAULT_BITRATE_KBPS = 96
SUPPORTED_BITRATES = {64, 96}

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


def _gemini_voice_lists_from_env() -> tuple[list[str], list[str]]:
    """Comma-separated Gemini prebuilt names from GEMINI_TTS_MALE_VOICES / FEMALE_VOICES."""
    male = _parse_voice_list(os.getenv("GEMINI_TTS_MALE_VOICES", ""))
    female = _parse_voice_list(os.getenv("GEMINI_TTS_FEMALE_VOICES", ""))
    if not male:
        male = ["Puck"]
    if not female:
        female = ["Leda"]
    return male, female


def load_gender_voice_context(repo_root: Path) -> GenderVoiceContext:
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
            pools = raw.get("characterNamePools") or {}
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
    m_voices, f_voices = _gemini_voice_lists_from_env()
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


def _gemini_voice_for_character(slug: str, ctx: GenderVoiceContext) -> str:
    """Random Gemini voice: gender lists if slug matches a pool name, else any gender."""
    gender = _gender_for_character(slug, ctx)
    if gender == "female":
        return random.choice(ctx.female_voices)
    if gender == "male":
        return random.choice(ctx.male_voices)
    return _random_gemini_voice_any_gender(ctx)


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
    """Resolve Gemini/ElevenLabs voice defaults from CLI and env (male/female voice lists)."""
    mlist, flist = _gemini_voice_lists_from_env()

    g_voice = args.voice if args.voice is not None else mlist[0]
    g_a = args.voice_a if args.voice_a is not None else mlist[0]
    g_b = args.voice_b if args.voice_b is not None else (flist[0] if flist else mlist[0])

    args.voice = g_voice
    args.voice_a = g_a
    args.voice_b = g_b

    pool = mlist + flist
    args._gemini_single_voice_pool = pool
    args._gemini_rotate_single = _env_truthy("GEMINI_TTS_VOICE_ROTATE")

    el_list = _parse_voice_list(os.getenv("ELEVENLABS_VOICE_IDS", ""))
    args._elevenlabs_voice_ids_pool = el_list
    args._elevenlabs_rotate = _env_truthy("ELEVENLABS_VOICE_ROTATE")


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
        "--provider",
        default="gemini",
        choices=["gemini", "elevenlabs"],
        help="TTS provider (default: gemini)",
    )
    parser.add_argument(
        "--workspace-root",
        default=None,
        help="Repo root path (defaults to script-relative root)",
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
        "--elevenlabs-voice",
        default=None,
        help="ElevenLabs single-speaker voice ID (or set ELEVENLABS_VOICE_ID)",
    )
    parser.add_argument(
        "--elevenlabs-voice-a",
        default=None,
        help="ElevenLabs voice ID A for ConvoTemplate-1 speaker A",
    )
    parser.add_argument(
        "--elevenlabs-voice-b",
        default=None,
        help="ElevenLabs voice ID B for ConvoTemplate-1 speaker B",
    )
    parser.add_argument(
        "--elevenlabs-model",
        default=ELEVENLABS_DEFAULT_MODEL,
        help=f"ElevenLabs model id (default: {ELEVENLABS_DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--output-suffix",
        default=None,
        help=(
            "Suffix added to output filename before .m4a "
            "(default: '' for gemini, '_elevenlabs' for elevenlabs)"
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


def resolve_paths(args: argparse.Namespace) -> tuple[Path, Path]:
    if args.workspace_root:
        repo_root = Path(args.workspace_root).expanduser().resolve()
    else:
        # tools/gemini_tts/generate_level_audio.py -> repo root is parents[2]
        repo_root = Path(__file__).resolve().parents[2]
    questions_path = (
        repo_root
        / "app"
        / "assets"
        / "quiz-data"
        / "levels"
        / args.level_id
        / "questions.json"
    )
    return repo_root, questions_path


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
    """Fill `sentence.en` blanks with ClozeSequence `answer`/`answers` (in order)."""
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


def _job_for_stem(
    idx: int,
    template: str,
    level_dir: Path,
    stem: str,
    output_suffix: str,
    tts_text: str,
    speaker_mode: str,
    speaker_a_name: str | None = None,
    speaker_b_name: str | None = None,
    gemini_voice_override: str | None = None,
) -> CandidateJob:
    output_filename = f"{stem}{output_suffix}.m4a"
    output_path = level_dir / output_filename
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


def build_jobs_for_question(
    level_id: str,
    level_dir: Path,
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

    # ConvoTemplate-DialogueCompletion: always two clips — line1, then answer (with blanks filled).
    if template == "ConvoTemplate-DialogueCompletion":
        qd = q.get("questionData")
        if not isinstance(qd, dict):
            return [
                CandidateJob(
                    question_index=idx,
                    template=template,
                    audio_file_value="",
                    output_filename=f"_invalid{output_suffix}.m4a",
                    output_path=level_dir / f"_invalid{output_suffix}.m4a",
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
                    output_path=level_dir / f"_invalid{output_suffix}.m4a",
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
                    output_path=level_dir / f"_invalid{output_suffix}.m4a",
                    tts_text=None,
                    speaker_mode="skip",
                    reason="dual_dialogue_missing_line1_or_answer",
                )
            ]
        text_answer = _replace_blanks_with_blank(answer)
        c1 = _str_or_none(qd.get("character1")) or "mike"
        c2 = _str_or_none(qd.get("character2")) or "sarah"
        v1 = (
            _gemini_voice_for_character(c1, gender_ctx)
            if gender_ctx is not None
            else None
        )
        # Pick v2 from the correct gender pool, excluding v1 to avoid same voice.
        if gender_ctx is not None:
            gender2 = _gender_for_character(c2, gender_ctx)
            pool2 = (
                gender_ctx.female_voices if gender2 == "female"
                else gender_ctx.male_voices if gender2 == "male"
                else tuple(list(gender_ctx.male_voices) + list(gender_ctx.female_voices))
            )
            v2 = _gemini_voice_excluding(pool2, v1)
        else:
            v2 = None
        # Filename gender hint overrides character-based voice for each clip.
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
                level_dir,
                af1,
                output_suffix,
                text1,
                "single",
                gemini_voice_override=v1,
            ),
            _job_for_stem(
                idx,
                template,
                level_dir,
                af2,
                output_suffix,
                text2,
                "single",
                gemini_voice_override=v2,
            ),
        ]

    job = build_job(level_id, level_dir, q, idx, output_suffix, gender_ctx)
    override_text = _str_or_none(q.get("audio_file_text"))
    if override_text and job.speaker_mode != "skip":
        job = replace(job, tts_text=override_text)
    return [job]


def build_job(
    level_id: str,
    level_dir: Path,
    q: dict[str, Any],
    idx: int,
    output_suffix: str,
    gender_ctx: GenderVoiceContext | None = None,
) -> CandidateJob:
    template = str(q.get("template", "")).strip()
    audio_file_value = _str_or_none(q.get("audio_file")) or ""
    output_filename = f"{audio_file_value}{output_suffix}.m4a"
    output_path = level_dir / output_filename

    # Derive a gender-specific voice override from the audio filename if the stem
    # contains "male" or "female" as a dash-separated token (e.g. "...-male-..." ).
    _filename_gender = _gender_from_audio_filename(audio_file_value)
    _filename_voice: str | None = (
        _gemini_voice_for_gender(_filename_gender, gender_ctx)
        if gender_ctx is not None and _filename_gender is not None
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
                reason="missing_line1_or_line2_en",
            )
        answer = _str_or_none(qd.get("answer"))
        line1_resolved = _normalize_spoken_line(
            _replace_blanks_with_answer(line1, answer)
        )
        line2_resolved = _normalize_spoken_line(
            _replace_blanks_with_answer(line2, answer)
        )
        char1 = _str_or_none(qd.get("character1")) or "SpeakerA"
        char2 = _str_or_none(qd.get("character2")) or "SpeakerB"
        text = f"{char1}: {line1_resolved}\n{char2}: {line2_resolved}"
        mva = (
            _gemini_voice_for_character(char1, gender_ctx)
            if gender_ctx is not None
            else None
        )
        if gender_ctx is not None:
            gender2 = _gender_for_character(char2, gender_ctx)
            pool2 = (
                gender_ctx.female_voices if gender2 == "female"
                else gender_ctx.male_voices if gender2 == "male"
                else tuple(list(gender_ctx.male_voices) + list(gender_ctx.female_voices))
            )
            mvb = _gemini_voice_excluding(pool2, mva)
        else:
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

    if template == "ConvoTemplate-AppearDisappear":
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

    if template == "ConvoTemplate-GrammarForm":
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

    if template == "ConvoTemplate-ClozeSequence":
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

    if template == "ConvoTemplate-SentenceBuilder":
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


def _retry_http(fn, attempts: int = 3, base_delay_s: float = 1.0) -> Any:
    last_exc: Exception | None = None
    for i in range(attempts):
        try:
            return fn()
        except requests.HTTPError as exc:
            status = exc.response.status_code if exc.response is not None else None
            retryable = status is None or status >= 500
            last_exc = exc
            if i == attempts - 1 or not retryable:
                break
            time.sleep(base_delay_s * (2**i))
        except requests.RequestException as exc:
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
) -> bytes:
    def _call() -> Any:
        return client.models.generate_content(
            model=MODEL_NAME,
            contents=f'Say in a clear, friendly tone for a young learner: "{text}"',
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


def generate_multi_speaker_pcm(
    client: genai.Client,
    text: str,
    speaker_a: str,
    speaker_b: str,
    voice_a: str,
    voice_b: str,
) -> bytes:
    def _call() -> Any:
        return client.models.generate_content(
            model=MODEL_NAME,
            contents=text,
            config=types.GenerateContentConfig(
                response_modalities=["AUDIO"],
                speech_config=types.SpeechConfig(
                    multi_speaker_voice_config=types.MultiSpeakerVoiceConfig(
                        speaker_voice_configs=[
                            types.SpeakerVoiceConfig(
                                speaker=speaker_a,
                                voice_config=types.VoiceConfig(
                                    prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                        voice_name=voice_a
                                    )
                                ),
                            ),
                            types.SpeakerVoiceConfig(
                                speaker=speaker_b,
                                voice_config=types.VoiceConfig(
                                    prebuilt_voice_config=types.PrebuiltVoiceConfig(
                                        voice_name=voice_b
                                    )
                                ),
                            ),
                        ]
                    )
                ),
            ),
        )

    response = _retry_call(_call)
    return extract_pcm_bytes(response)


def elevenlabs_single_speaker_mp3(
    *,
    text: str,
    api_key: str,
    voice_id: str,
    model_id: str,
) -> bytes:
    def _call() -> bytes:
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        response = requests.post(
            url,
            headers={
                "xi-api-key": api_key,
                "Content-Type": "application/json",
                "Accept": "audio/mpeg",
            },
            json={
                "text": text,
                "model_id": model_id,
                "voice_settings": {
                    "stability": 0.5,
                    "similarity_boost": 0.75,
                },
            },
            timeout=45,
        )
        response.raise_for_status()
        return response.content

    return _retry_http(_call)


def elevenlabs_multi_speaker_mp3(
    *,
    line_a: str,
    line_b: str,
    api_key: str,
    voice_id_a: str,
    voice_id_b: str,
    model_id: str,
) -> bytes:
    from pydub import AudioSegment

    part_a = elevenlabs_single_speaker_mp3(
        text=line_a,
        api_key=api_key,
        voice_id=voice_id_a,
        model_id=model_id,
    )
    part_b = elevenlabs_single_speaker_mp3(
        text=line_b,
        api_key=api_key,
        voice_id=voice_id_b,
        model_id=model_id,
    )
    seg_a = AudioSegment.from_file(io.BytesIO(part_a), format="mp3")
    seg_b = AudioSegment.from_file(io.BytesIO(part_b), format="mp3")
    merged = seg_a + AudioSegment.silent(duration=250) + seg_b
    out_buf = io.BytesIO()
    merged.export(out_buf, format="mp3", bitrate="128k")
    return out_buf.getvalue()


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


def mp3_to_m4a_file(mp3_bytes: bytes, output_path: Path, bitrate_kbps: int) -> None:
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp_mp3_path = Path(tmp.name)
        tmp.write(mp3_bytes)
    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                str(tmp_mp3_path),
                "-c:a",
                "aac",
                "-b:a",
                f"{bitrate_kbps}k",
                str(output_path),
            ],
            check=True,
        )
    finally:
        if tmp_mp3_path.exists():
            tmp_mp3_path.unlink(missing_ok=True)


def ensure_ffmpeg_available() -> None:
    if shutil.which("ffmpeg") is None:
        raise SystemExit(
            "ffmpeg is required for M4A conversion but was not found on PATH."
        )


def main() -> None:
    args = parse_args()
    repo_root, questions_path = resolve_paths(args)
    if not questions_path.is_file():
        raise SystemExit(f"questions.json not found: {questions_path}")

    load_dotenv()
    explicit_gemini_voice = args.voice is not None
    configure_tts_voices(args)

    google_api_key = os.getenv("GOOGLE_API_KEY", "").strip()
    elevenlabs_api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    if not args.dry_run and args.provider == "gemini" and not google_api_key:
        raise SystemExit("GOOGLE_API_KEY is missing for provider=gemini.")
    if not args.dry_run and args.provider == "elevenlabs" and not elevenlabs_api_key:
        raise SystemExit("ELEVENLABS_API_KEY is missing for provider=elevenlabs.")

    elevenlabs_voice_single = (
        args.elevenlabs_voice or os.getenv("ELEVENLABS_VOICE_ID", "")
    ).strip()
    el_pool = getattr(args, "_elevenlabs_voice_ids_pool", []) or []
    if not elevenlabs_voice_single and el_pool:
        elevenlabs_voice_single = el_pool[0]
    elevenlabs_voice_a = (
        args.elevenlabs_voice_a or os.getenv("ELEVENLABS_VOICE_ID_A", "")
    ).strip()
    elevenlabs_voice_b = (
        args.elevenlabs_voice_b or os.getenv("ELEVENLABS_VOICE_ID_B", "")
    ).strip()
    if args.provider == "elevenlabs":
        if not elevenlabs_voice_single:
            raise SystemExit(
                "ElevenLabs single voice ID missing. Use --elevenlabs-voice "
                "or set ELEVENLABS_VOICE_ID or ELEVENLABS_VOICE_IDS."
            )
        if not elevenlabs_voice_a:
            elevenlabs_voice_a = elevenlabs_voice_single
        if not elevenlabs_voice_b:
            elevenlabs_voice_b = elevenlabs_voice_single

    el_single_pool = el_pool if el_pool else (
        [elevenlabs_voice_single] if elevenlabs_voice_single else []
    )
    el_rotate = getattr(args, "_elevenlabs_rotate", False)

    output_suffix = args.output_suffix
    if output_suffix is None:
        output_suffix = "" if args.provider == "gemini" else "_elevenlabs"

    rows = parse_questions(questions_path)
    level_dir = questions_path.parent
    ensure_ffmpeg_available()

    gender_ctx = (
        load_gender_voice_context(repo_root)
        if args.provider == "gemini"
        else None
    )

    jobs: list[CandidateJob] = []
    for idx, q in enumerate(rows):
        if args.question is not None and idx != args.question:
            continue
        jobs.extend(
            build_jobs_for_question(
                args.level_id, level_dir, q, idx, output_suffix, gender_ctx
            )
        )

    # Single-speaker clips without character-based routing: random voice from male+female pool.
    # (Character-routed jobs already set gemini_voice_override; respect --voice and rotation.)
    if (
        args.provider == "gemini"
        and not explicit_gemini_voice
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
    print(f"Questions file: {questions_path}")
    print(f"Candidate rows considered: {len(jobs)}")
    if args.provider == "gemini" and gender_ctx is not None:
        print(
            f"Gemini male voices: {list(gender_ctx.male_voices)}  "
            f"female voices: {list(gender_ctx.female_voices)}"
        )
    if args.provider == "gemini":
        print(
            f"Gemini voices: single={args.voice}  A={args.voice_a}  B={args.voice_b}"
        )
        if getattr(args, "_gemini_rotate_single", False):
            print(
                f"  single-speaker rotation pool: "
                f"{getattr(args, '_gemini_single_voice_pool', [])}"
            )
    if args.provider == "elevenlabs":
        print(
            f"ElevenLabs voices: single={elevenlabs_voice_single}  "
            f"A={elevenlabs_voice_a}  B={elevenlabs_voice_b}"
        )
        if el_rotate and el_single_pool:
            print(f"  single-speaker rotation pool: {el_single_pool}")

    generated = 0
    skipped_no_audio_file = 0
    skipped_unsupported_template = 0
    skipped_existing = 0
    failed = 0

    client = None
    if not args.dry_run and args.provider == "gemini":
        client = genai.Client(api_key=google_api_key)

    gemini_single_ctr = 0
    elevenlabs_single_ctr = 0

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
                f"{prefix} DRY-RUN mode={job.speaker_mode} -> {job.output_filename}"
            )
            print(f"  text: {job.tts_text}")
            if args.provider == "gemini":
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
            if args.provider == "gemini" and job.speaker_mode == "multi":
                assert client is not None
                va = job.gemini_multi_voice_a or args.voice_a
                vb = job.gemini_multi_voice_b or args.voice_b
                lines = job.tts_text.splitlines()
                line_a = lines[0] if lines else job.tts_text
                line_b = lines[1] if len(lines) > 1 else ""
                line_a = line_a.split(":", 1)[-1].strip() if ":" in line_a else line_a
                line_b = line_b.split(":", 1)[-1].strip() if ":" in line_b else line_b
                pcm_a = generate_single_speaker_pcm(client=client, text=line_a, voice=va)
                pcm_b = generate_single_speaker_pcm(client=client, text=line_b, voice=vb)
                pcm_bytes = pcm_a + _silence_pcm(300) + pcm_b
                pcm_to_m4a_file(
                    pcm_bytes=pcm_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            elif args.provider == "gemini":
                assert client is not None
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
                )
                pcm_to_m4a_file(
                    pcm_bytes=pcm_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            elif job.speaker_mode == "multi":
                lines = job.tts_text.splitlines()
                line_a = lines[0] if lines else job.tts_text
                line_b = lines[1] if len(lines) > 1 else ""
                line_a = line_a.split(":", 1)[-1].strip() if ":" in line_a else line_a
                line_b = line_b.split(":", 1)[-1].strip() if ":" in line_b else line_b
                mp3_bytes = elevenlabs_multi_speaker_mp3(
                    line_a=line_a,
                    line_b=line_b,
                    api_key=elevenlabs_api_key,
                    voice_id_a=elevenlabs_voice_a,
                    voice_id_b=elevenlabs_voice_b,
                    model_id=args.elevenlabs_model,
                )
                mp3_to_m4a_file(
                    mp3_bytes=mp3_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            else:
                voice_el = elevenlabs_voice_single
                if el_rotate and el_single_pool:
                    voice_el = el_single_pool[
                        elevenlabs_single_ctr % len(el_single_pool)
                    ]
                    elevenlabs_single_ctr += 1
                mp3_bytes = elevenlabs_single_speaker_mp3(
                    text=job.tts_text,
                    api_key=elevenlabs_api_key,
                    voice_id=voice_el,
                    model_id=args.elevenlabs_model,
                )
                mp3_to_m4a_file(
                    mp3_bytes=mp3_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            generated += 1
            print(f"{prefix} OK wrote {job.output_filename}")
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
