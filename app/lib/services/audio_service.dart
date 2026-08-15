import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../app_flavor.dart';

String get _quizMusicAsset => 'audio/${AppConfig.flavorDir}/quiz_music.mp3';
String get _clickAsset => 'audio/${AppConfig.flavorDir}/click.mp3';
String get _correctAsset => 'audio/${AppConfig.flavorDir}/correct.mp3';
String get _wrongAsset => 'audio/${AppConfig.flavorDir}/wrong.mp3';

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
  final player = _ttsPlayerInstance();
  try {
    try {
      await player.stop();
    } catch (_) {}

    await player.setReleaseMode(ReleaseMode.release);
    final completer = Completer<void>();
    late final StreamSubscription<void> sub;
    sub = player.onPlayerComplete.listen((_) {
      sub.cancel();
      if (!completer.isCompleted) completer.complete();
    });
    try {
      await _startQuestionAudioPlayback(player, assetPath);
    } catch (e, st) {
      sub.cancel();
      if (!completer.isCompleted) completer.completeError(e, st);
      rethrow;
    }
    return completer.future;
  } catch (e, st) {
    if (e.toString().contains('AbortError')) return;
    debugPrint('AudioService.playQuestionAudio: $e\n$st');
  }
}

/// Starts a question clip and completes as soon as the platform reports that playback
/// has begun. This is intentionally separate from [playQuestionAudio], whose Future
/// completes when the clip ends.
Future<void> startQuestionAudio(String assetPath) async {
  final player = _ttsPlayerInstance();
  try {
    try {
      await player.stop();
    } catch (_) {}
    await player.setReleaseMode(ReleaseMode.release);
    await _startQuestionAudioPlayback(player, assetPath);
  } catch (e, st) {
    if (e.toString().contains('AbortError')) return;
    debugPrint('AudioService.startQuestionAudio: $e\n$st');
  }
}

Future<void> _startQuestionAudioPlayback(
  AudioPlayer player,
  String assetPath,
) async {
  final started = Completer<void>();
  late final StreamSubscription<PlayerState> sub;
  sub = player.onPlayerStateChanged.listen((state) {
    if (state == PlayerState.playing && !started.isCompleted) {
      debugPrint(
        'Question audio started: ${DateTime.now().millisecondsSinceEpoch} ms '
        '(asset: $assetPath)',
      );
      started.complete();
      sub.cancel();
    }
  });
  try {
    await player.play(AssetSource(assetPath));
    await started.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
  } finally {
    if (!started.isCompleted) started.complete();
    await sub.cancel();
  }
}

Future<void> stopQuestionAudio() async {
  try {
    await _ttsPlayer?.stop();
  } catch (e, st) {
    debugPrint('AudioService.stopQuestionAudio: $e\n$st');
  }
}
