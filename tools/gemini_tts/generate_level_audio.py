#!/usr/bin/env python3
"""Generate per-level quiz audio assets with Gemini TTS.

Development-time only utility:
- Reads app/assets/quiz-data/levels/{level_id}/questions.json
- Generates .m4a only for questions with top-level "audio_file"
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
import subprocess
import tempfile
import time
import wave
from dataclasses import dataclass
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
        default=DEFAULT_SINGLE_VOICE,
        help=f"Gemini single-speaker voice (default: {DEFAULT_SINGLE_VOICE})",
    )
    parser.add_argument(
        "--voice-a",
        default=DEFAULT_VOICE_A,
        help=f"Gemini multi-speaker voice A for character1 (default: {DEFAULT_VOICE_A})",
    )
    parser.add_argument(
        "--voice-b",
        default=DEFAULT_VOICE_B,
        help=f"Gemini multi-speaker voice B for character2 (default: {DEFAULT_VOICE_B})",
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
    # Gemini: use long-pause markers around cloze gaps.
    # Example: "I _____ tea" -> "I [long pause] Blank [long pause] tea"
    replaced = BLANK_RE.sub(" [long pause] Blank [long pause] ", text)
    # Normalize spacing around punctuation.
    replaced = re.sub(r"\s+([,.;!?])", r"\1", replaced)
    replaced = re.sub(r"\s+", " ", replaced).strip()
    return replaced


def _replace_blanks_with_silence_blank(text: str) -> str:
    # Keep ConvoTemplate-1 line2 aligned with generic Gemini blank handling.
    return _replace_blanks_with_blank(text)


def _replace_blanks_with_answer(text: str, answer: str | None) -> str:
    if answer and answer.strip():
        return BLANK_RE.sub(answer.strip(), text)
    return _replace_blanks_with_blank(text)


def _join_words(value: Any) -> str | None:
    if isinstance(value, str):
        out = [x for x in value.strip().split() if x]
        return " ".join(out) if out else None
    if not isinstance(value, list):
        return None
    out = [str(x).strip() for x in value if str(x).strip()]
    if not out:
        return None
    return " ".join(out)


def build_job(
    level_id: str,
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
        line1_resolved = _replace_blanks_with_answer(line1, answer)
        line2_resolved = _replace_blanks_with_silence_blank(line2)
        char1 = _str_or_none(qd.get("character1")) or "SpeakerA"
        char2 = _str_or_none(qd.get("character2")) or "SpeakerB"
        text = f"{char1}: {line1_resolved}\n{char2}: {line2_resolved}"
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
        )

    if template == "ConvoTemplate-AppearDisappear":
        text = _join_words(qd.get("words"))
        if text:
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
            )

    if template == "ConvoTemplate-Simon":
        text = _join_words(qd.get("words"))
        if text:
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
            )

    if template in {"ConvoTemplate-ClozeSequence", "ConvoTemplate-GrammarForm"}:
        sentence_en = _localized_en(qd.get("sentence"))
        if sentence_en:
            text = _replace_blanks_with_blank(sentence_en)
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=text,
                speaker_mode="single",
            )

    if template == "ConvoTemplate-DialogueCompletion":
        line1 = _localized_en(qd.get("line1"))
        if line1:
            return CandidateJob(
                question_index=idx,
                template=template,
                audio_file_value=audio_file_value,
                output_filename=output_filename,
                output_path=output_path,
                tts_text=line1,
                speaker_mode="single",
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
    google_api_key = os.getenv("GOOGLE_API_KEY", "").strip()
    elevenlabs_api_key = os.getenv("ELEVENLABS_API_KEY", "").strip()
    if not args.dry_run and args.provider == "gemini" and not google_api_key:
        raise SystemExit("GOOGLE_API_KEY is missing for provider=gemini.")
    if not args.dry_run and args.provider == "elevenlabs" and not elevenlabs_api_key:
        raise SystemExit("ELEVENLABS_API_KEY is missing for provider=elevenlabs.")

    elevenlabs_voice_single = (
        args.elevenlabs_voice or os.getenv("ELEVENLABS_VOICE_ID", "")
    ).strip()
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
                "or set ELEVENLABS_VOICE_ID."
            )
        if not elevenlabs_voice_a:
            elevenlabs_voice_a = elevenlabs_voice_single
        if not elevenlabs_voice_b:
            elevenlabs_voice_b = elevenlabs_voice_single

    output_suffix = args.output_suffix
    if output_suffix is None:
        output_suffix = "" if args.provider == "gemini" else "_elevenlabs"

    rows = parse_questions(questions_path)
    level_dir = questions_path.parent
    ensure_ffmpeg_available()

    jobs: list[CandidateJob] = []
    for idx, q in enumerate(rows):
        if args.question is not None and idx != args.question:
            continue
        jobs.append(build_job(args.level_id, level_dir, q, idx, output_suffix))

    print(f"Repo root: {repo_root}")
    print(f"Level: {args.level_id}")
    print(f"Questions file: {questions_path}")
    print(f"Candidate rows considered: {len(jobs)}")

    generated = 0
    skipped_no_audio_file = 0
    skipped_unsupported_template = 0
    skipped_existing = 0
    failed = 0

    client = None
    if not args.dry_run and args.provider == "gemini":
        client = genai.Client(api_key=google_api_key)

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
            generated += 1
            continue

        try:
            assert client is not None
            if args.provider == "gemini" and job.speaker_mode == "multi":
                assert client is not None
                pcm_bytes = generate_multi_speaker_pcm(
                    client=client,
                    text=job.tts_text,
                    speaker_a=job.speaker_a_name or "SpeakerA",
                    speaker_b=job.speaker_b_name or "SpeakerB",
                    voice_a=args.voice_a,
                    voice_b=args.voice_b,
                )
                pcm_to_m4a_file(
                    pcm_bytes=pcm_bytes,
                    output_path=job.output_path,
                    bitrate_kbps=args.bitrate,
                )
            elif args.provider == "gemini":
                assert client is not None
                pcm_bytes = generate_single_speaker_pcm(
                    client=client,
                    text=job.tts_text,
                    voice=args.voice,
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
                mp3_bytes = elevenlabs_single_speaker_mp3(
                    text=job.tts_text,
                    api_key=elevenlabs_api_key,
                    voice_id=elevenlabs_voice_single,
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
