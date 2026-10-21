import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/helpers/desktop_audio_duration.dart';

class _DurationPlayer extends Fake implements AudioPlayer {
  final events = StreamController<Duration?>.broadcast();
  @override
  Duration? get duration => Duration.zero;
  @override
  Stream<Duration?> get durationStream => events.stream;
}
class _UnqueriedPlayer extends Fake implements AudioPlayer {}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  test('Windows finite previews wait for the native duration event', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final player = _DurationPlayer();
    try {
      final ready = readyAudioDuration(player, null);
      player.events.add(Duration.zero);
      player.events.add(const Duration(seconds: 2));
      expect(await ready, const Duration(seconds: 2));
    } finally { await player.events.close(); }
  });
  test('known Windows duration is immediately reusable', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(await readyAudioDuration(_UnqueriedPlayer(), const Duration(seconds: 1)),
      const Duration(seconds: 1));
  });
  test('Android keeps the original load response without a desktop wait', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(await readyAudioDuration(_UnqueriedPlayer(), null), isNull);
  });
}
