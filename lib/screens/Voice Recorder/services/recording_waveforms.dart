import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'file_service.dart';
import 'recording_service.dart';

/// Ten amplitude samples per second, shared by recording and playback.
class RecordingWaveforms {
  static final memory = <String, List<double>>{};
  static final pending = <String, Future<List<double>>>{};
  static String key(String path) => 'recording.waveform.v1.$path';
  static Future<void> save(String path, List<double> samples) async {
    memory[path] = List.of(samples);
    final bytes = Uint8List.fromList(
      samples.map((v) => (v.clamp(0, 1) * 255).round()).toList(),
    );
    try {
      await (await SharedPreferences.getInstance()).setString(
        key(path),
        base64Encode(bytes),
      );
    } catch (_) {
      /* Wave cache is optional. */
    }
  }

  static Future<List<double>?> cached(String path) async {
    if (memory.containsKey(path)) return memory[path];
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key(path));
      if (raw != null)
        return memory[path] = base64Decode(raw).map((v) => v / 255).toList();
    } catch (_) {
      /* Rebuild invalid cache. */
    }
    return null;
  }

  static Future<void> move(String before, String? after) async {
    if (before == after) return;
    final samples = await cached(before);
    if (samples != null && after != null) await save(after, samples);
    memory.remove(before);
    try {
      await (await SharedPreferences.getInstance()).remove(key(before));
    } catch (_) {}
  }

  static Future<List<double>> load(SavedRecording file, FileService service) =>
      pending.putIfAbsent(
        file.uri,
        () => _load(file, service).whenComplete(() {
          pending.remove(file.uri);
        }),
      );
  static Future<List<double>> _load(
    SavedRecording file,
    FileService service,
  ) async {
    final existing = await cached(file.uri);
    if (existing != null) return existing;
    if (kIsWeb) return [];
    File? temporary, wave;
    try {
      final path = await service.materialize(file);
      temporary = file.isPublic ? File(path) : null;
      wave = File('$path.${DateTime.now().microsecondsSinceEpoch}.waveform');
      final result = await JustWaveform.extract(
        audioInFile: File(path),
        waveOutFile: wave,
        zoom: const WaveformZoom.pixelsPerSecond(10),
      ).last;
      final waveform = result.waveform;
      if (waveform == null) throw StateError('No waveform');
      final scale = waveform.flags & 1 == 1 ? 128.0 : 32768.0;
      final samples = [
        for (var i = 0; i < waveform.length; i++)
          recordingAmplitude(
            20 *
                math.log(
                  math.max(
                        waveform.getPixelMin(i).abs(),
                        waveform.getPixelMax(i).abs(),
                      ) /
                      scale,
                ) /
                math.ln10,
          ),
      ];
      await save(file.uri, samples);
      return samples;
    } finally {
      if (wave != null && await wave.exists()) await wave.delete();
      if (temporary != null && await temporary.exists())
        await temporary.delete();
    }
  }

  static Future<void> warm(
    List<SavedRecording> files,
    FileService service,
  ) async {
    for (final file in files) {
      try {
        await load(file, service);
      } catch (_) {
        /* Retry when opened. */
      }
    }
  }
}
