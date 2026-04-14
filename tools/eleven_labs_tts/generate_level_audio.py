#!/usr/bin/env python3
"""Generate per-level quiz audio assets with ElevenLabs TTS.

Development-time only utility:
- Reads app/assets/quiz-data/levels/{level_id}/questions.json
- Generates .m4a for top-level "audio_file" or DialogueCompletion "audio_file1"+"audio_file2"
- Writes output files into the same level folder
- Does NOT modify questions.json
"""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import shutil
import tempfile
import time
import wave
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from pydub import AudioSegment
import requests

DEFAULT_MODEL_ID = "eleven_flash_v2_5"
DEFAULT_BITRATE_KBPS = 96
SUPPORTED_BITRATES = {64, 96}
BLANK_RE = re.compile(r"_{2,}")


@dataclass(frozen=True)
class CandidateJob:
    question_index: int
    template: str
    audio_file_value: str
    output_filename: str
    output_path: Path
    tts_text: str | None
    speaker_mode: str  # "single" | "multi" | "skip"
    line_a: str | None = None
    line_b: str | None = None
    reason: str | None = None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate ElevenLabs TTS .m4a files for one level."
    )
    parser.add_argument("--level-id", required=True, help="Level folder name")
    parser.add_argument(
        "--workspace-root",
        default=None,
        help="Repo root path (defaults to script-relative root)",
    )
    parser.add_argument(
        "--voice-id",
        default=None,
        help="Single-speaker ElevenLabs voice id (or set ELEVENLABS_VOICE_ID)",
    )
    parser.add_argument(
        "--voice-a-id",
        default=None,
        help="ConvoTemplate-1 speaker A voice id",
    )
    parser.add_argument(
        "--voice-b-id",
        default=None,
        help="ConvoTemplate-1 speaker B voice id",
    )
    parser.add_argument(
        "--model-id",
        default=DEFAULT_MODEL_ID,
        help=f"ElevenLabs model id (default: {DEFAULT_MODEL_ID})",
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
    parser.add_argument(
        "--output-suffix",
        default="_elevenlabs",
        help="Suffix added to output filename before .m4a (default: _elevenlabs)",
    )
    return parser.parse_args()


def resolve_paths(args: argparse.Namespace) -> tuple[Path, Path]:
    if args.workspace_root:
        repo_root = Path(args.workspace_root).expanduser().resolve()
    else:
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
    replaced = BLANK_RE.sub(" [long pause] ", text)
    # Normalize whitespace and punctuation adjacency.
    replaced = re.sub(r"\s+([,.;!?])", r"\1", replaced)
    replaced = re.sub(r"\s+", " ", replaced).strip()
    replaced = re.sub(r"\s*\[long pause\]\s*$", "", replaced).strip()
    return replaced


def _replace_blanks_with_answer(text: str, answer: str | None) -> str:
    if answer and answer.strip():
        return BLANK_RE.sub(answer.strip(), text)
    return _replace_blanks_with_blank(text)


def _normalize_spoken_line(text: str) -> str:
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
    line_a: str | None = None,
    line_b: str | None = None,
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
        line_a=line_a,
        line_b=line_b,
    )


def build_jobs_for_question(
    level_dir: Path,
    q: dict[str, Any],
    idx: int,
    output_suffix: str,
) -> list[CandidateJob]:
    template = str(q.get("template", "")).strip()
    af1 = _str_or_none(q.get("audio_file1"))
    af2 = _str_or_none(q.get("audio_file2"))

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
        return [
            _job_for_stem(
                idx, template, level_dir, af1, output_suffix, line1, "single"
            ),
            _job_for_stem(
                idx, template, level_dir, af2, output_suffix, text_answer, "single"
            ),
        ]

    return [build_job(level_dir, q, idx, output_suffix)]


def build_job(
    level_dir: Path,
    q: dict[str, Any],
    idx: int,
    output_suffix: str,
) -> CandidateJob:
    template = str(q.get("template", "")).strip()
    audio_file_value = _str_or_none(q.get("audio_file")) or ""
    output_filename = f"{audio_file_value}{output_suffix}.m4a"
    output_path = level_dir / output_filename

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
        line1 = _normalize_spoken_line(_replace_blanks_with_answer(line1, answer))
        line2 = _normalize_spoken_line(_replace_blanks_with_answer(line2, answer))
        return CandidateJob(
            question_index=idx,
            template=template,
            audio_file_value=audio_file_value,
            output_filename=output_filename,
            output_path=output_path,
            tts_text=f"{line1} {line2}",
            speaker_mode="multi",
            line_a=line1,
            line_b=line2,
        )

    if template == "ConvoTemplate-AppearDisappear":
        words = _words_list(qd.get("words"))
        if words:
            text = " [long pause] ".join(words)
            return CandidateJob(idx, template, audio_file_value, output_filename, output_path, text, "single")

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
            return CandidateJob(idx, template, audio_file_value, output_filename, output_path, text, "single")

    if template == "ConvoTemplate-SentenceBuilder":
        text = _join_words(qd.get("correct_order"))
        if text:
            return CandidateJob(idx, template, audio_file_value, output_filename, output_path, text, "single")

    if template == "imageQuizTemplate-2":
        answer = _str_or_none(qd.get("answer"))
        if answer:
            return CandidateJob(idx, template, audio_file_value, output_filename, output_path, answer, "single")

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


def _retry_http(fn, attempts: int = 3, base_delay_s: float = 1.0) -> bytes:
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


def mp3_to_m4a_file(mp3_bytes: bytes, output_path: Path, bitrate_kbps: int) -> None:
    audio = AudioSegment.from_file(io.BytesIO(mp3_bytes), format="mp3")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    audio.export(str(output_path), format="ipod", bitrate=f"{bitrate_kbps}k")


def ensure_ffmpeg_available() -> None:
    converter = AudioSegment.converter or "ffmpeg"
    if shutil.which(converter) is None:
        raise SystemExit(
            "ffmpeg is required for M4A conversion but was not found on PATH."
        )


def main() -> None:
    args = parse_args()
    repo_root, questions_path = resolve_paths(args)
    if not questions_path.is_file():
        raise SystemExit(f"questions.json not found: {questions_path}")

    load_dotenv()
    api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    if not args.dry_run and not api_key:
        raise SystemExit("ELEVENLABS_API_KEY is missing.")

    voice_single = (args.voice_id or os.getenv("ELEVENLABS_VOICE_ID", "")).strip()
    voice_a = (args.voice_a_id or os.getenv("ELEVENLABS_VOICE_ID_A", "")).strip()
    voice_b = (args.voice_b_id or os.getenv("ELEVENLABS_VOICE_ID_B", "")).strip()
    if not args.dry_run and not voice_single:
        raise SystemExit("Voice id missing. Use --voice-id or ELEVENLABS_VOICE_ID.")
    if not voice_a:
        voice_a = voice_single
    if not voice_b:
        voice_b = voice_single

    rows = parse_questions(questions_path)
    level_dir = questions_path.parent
    ensure_ffmpeg_available()

    jobs: list[CandidateJob] = []
    for idx, q in enumerate(rows):
        if args.question is not None and idx != args.question:
            continue
        jobs.extend(build_jobs_for_question(level_dir, q, idx, args.output_suffix))

    print(f"Repo root: {repo_root}")
    print(f"Level: {args.level_id}")
    print(f"Questions file: {questions_path}")
    print(f"Candidate rows considered: {len(jobs)}")

    generated = 0
    skipped_no_audio_file = 0
    skipped_unsupported_template = 0
    skipped_existing = 0
    failed = 0

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
            print(f"{prefix} DRY-RUN mode={job.speaker_mode} -> {job.output_filename}")
            print(f"  text: {job.tts_text}")
            generated += 1
            continue

        try:
            if job.speaker_mode == "multi":
                mp3_bytes = elevenlabs_multi_speaker_mp3(
                    line_a=job.line_a or "",
                    line_b=job.line_b or "",
                    api_key=api_key,
                    voice_id_a=voice_a,
                    voice_id_b=voice_b,
                    model_id=args.model_id,
                )
            else:
                mp3_bytes = elevenlabs_single_speaker_mp3(
                    text=job.tts_text,
                    api_key=api_key,
                    voice_id=voice_single,
                    model_id=args.model_id,
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

