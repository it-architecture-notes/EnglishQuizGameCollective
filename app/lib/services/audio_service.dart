import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

const String _quizMusicAsset = 'audio/quiz_music.mp3';
const String _clickAsset = 'audio/click.mp3';
const String _correctAsset = 'audio/correct.mp3';
const String _wrongAsset = 'audio/wrong.mp3';

AudioPlayer? _musicPlayer;
AudioPlayer? _sfxPlayer;
AudioPlayer? _ttsPlayer;

AudioPlayer _musicPlayerInstance() {
  _musicPlayer ??= AudioPlayer();
  return _musicPlayer!;
}

AudioPlayer _sfxPlayerInstance() {
  _sfxPlayer ??= AudioPlayer();
  return _sfxPlayer!;
}

AudioPlayer _ttsPlayerInstance() {
  _ttsPlayer ??= AudioPlayer();
  return _ttsPlayer!;
}

Future<void> startQuizMusic({required bool musicOn}) async {
  if (!musicOn) return;
  try {
    final player = _musicPlayerInstance();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource(_quizMusicAsset));
  } catch (e, st) {
    debugPrint('AudioService.startQuizMusic: $e\n$st');
  }
}

Future<void> stopQuizMusic() async {
  try {
    await _musicPlayer?.stop();
  } catch (e, st) {
    debugPrint('AudioService.stopQuizMusic: $e\n$st');
  }
}

Future<void> playClick({required bool soundFxOn}) async {
  if (!soundFxOn) return;
  try {
    final player = _sfxPlayerInstance();
    // On web, stop() can throw AbortError if play() hasn't finished.
    // We catch it and move on.
    try {
      await player.stop();
    } catch (_) {}
    
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(_clickAsset));
  } catch (e, st) {
    if (e.toString().contains('AbortError')) return;
    debugPrint('AudioService.playClick: $e\n$st');
  }
}

Future<void> playCorrect({required bool soundFxOn}) async {
  if (!soundFxOn) return;
  try {
    final player = _sfxPlayerInstance();
    try {
      await player.stop();
    } catch (_) {}

    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(_correctAsset));
  } catch (e, st) {
    if (e.toString().contains('AbortError')) return;
    debugPrint('AudioService.playCorrect: $e\n$st');
  }
}

Future<void> playWrong({required bool soundFxOn}) async {
  if (!soundFxOn) return;
  try {
    final player = _sfxPlayerInstance();
    try {
      await player.stop();
    } catch (_) {}

    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(_wrongAsset));
  } catch (e, st) {
    if (e.toString().contains('AbortError')) return;
    debugPrint('AudioService.playWrong: $e\n$st');
  }
}

Future<void> playQuestionAudio(String assetPath) async {
  try {
    final player = _ttsPlayerInstance();
    try {
      await player.stop();
    } catch (_) {}

    await player.setReleaseMode(ReleaseMode.release);
    await player.play(AssetSource(assetPath));
  } catch (e, st) {
    if (e.toString().contains('AbortError')) return;
    debugPrint('AudioService.playQuestionAudio: $e\n$st');
  }
}

Future<void> stopQuestionAudio() async {
  try {
    await _ttsPlayer?.stop();
  } catch (e, st) {
    debugPrint('AudioService.stopQuestionAudio: $e\n$st');
  }
}
