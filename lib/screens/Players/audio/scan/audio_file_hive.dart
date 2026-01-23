import 'dart:io';
import 'package:hive/hive.dart';
import 'package:sornaz/screens/Players/audio/scan/audio_file.dart';

part 'audio_file_hive.g.dart';

@HiveType(typeId: 0)
class AudioFileHive extends HiveObject {
  @HiveField(0)
  String filePath;

  @HiveField(1)
  String fileName;

  @HiveField(2)
  String folderName;

  @HiveField(3)
  int durationMs;

  AudioFileHive({
    required this.filePath,
    required this.fileName,
    required this.folderName,
    required this.durationMs,
  });

  AudioFile toAudioFile() {
    return AudioFile(
      file: File(filePath),
      fileName: fileName,
      folderName: folderName,
      duration: Duration(milliseconds: durationMs),
      metadata: null,
    );
  }

  factory AudioFileHive.fromAudioFile(AudioFile audio) {
    return AudioFileHive(
      filePath: audio.file.path,
      fileName: audio.fileName,
      folderName: audio.folderName,
      durationMs: audio.duration.inMilliseconds,
    );
  }
}