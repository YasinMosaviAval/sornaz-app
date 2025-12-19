import 'dart:io';
import 'package:hive/hive.dart';
import 'package:sornaz/audio/scan/audio_file.dart';
// import 'audio_metadata.dart';

part 'audio_file_hive.g.dart'; // تولید می‌شه

@HiveType(typeId: 0)
class AudioFileHive extends HiveObject {
  @HiveField(0)
  String filePath;

  @HiveField(1)
  String fileName;

  @HiveField(2)
  String folderName;

  @HiveField(3)
  int durationMs; // Duration رو به میلی‌ثانیه ذخیره کن

  AudioFileHive({
    required this.filePath,
    required this.fileName,
    required this.folderName,
    required this.durationMs,
  });

  // تبدیل به AudioFile اصلی
  AudioFile toAudioFile() {
    return AudioFile(
      file: File(filePath),
      fileName: fileName,
      folderName: folderName,
      duration: Duration(milliseconds: durationMs),
      metadata: null, // metadata رو بعداً می‌تونی اضافه کنی
    );
  }

  // از AudioFile اصلی
  factory AudioFileHive.fromAudioFile(AudioFile audio) {
    return AudioFileHive(
      filePath: audio.file.path,
      fileName: audio.fileName,
      folderName: audio.folderName,
      durationMs: audio.duration.inMilliseconds,
    );
  }
}