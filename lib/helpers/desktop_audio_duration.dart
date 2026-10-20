import 'package:just_audio/just_audio.dart';
import 'app_platform.dart';

/// Windows acknowledges a load before Media Foundation publishes its duration.
/// Finite file/asset previews must wait for that event before enabling seeking.
Future<Duration?> readyAudioDuration(
  AudioPlayer player,
  Duration? initial,
) async {
  if (!AppPlatform.isWindows || (initial != null && initial > Duration.zero))
    return initial;
  final current = player.duration;
  if (current != null && current > Duration.zero) return current;
  return player.durationStream
      .firstWhere((value) => value != null && value > Duration.zero)
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw StateError('Audio duration is unavailable.'),
      );
}
