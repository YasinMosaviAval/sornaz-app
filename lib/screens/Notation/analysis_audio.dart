import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum AnalysisAudioErrorCode {
  missingFile,
  unsupportedFormat,
  cancelled,
  decodeFailed,
  invalidData,
  ioFailure,
}

class AnalysisAudioException implements Exception {
  const AnalysisAudioException(this.code, this.message);
  final AnalysisAudioErrorCode code;
  final String message;
  @override
  String toString() => 'AnalysisAudioException($code): $message';
}

class AnalysisCancellation {
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  void throwIfCancelled() {
    if (isCancelled) {
      throw const AnalysisAudioException(
        AnalysisAudioErrorCode.cancelled,
        'Audio preparation was cancelled.',
      );
    }
  }
}

/// A private file path, or an Android content URI. No recorder dependency.
class AnalysisAudioSource {
  const AnalysisAudioSource.file(this.location) : isContentUri = false;
  const AnalysisAudioSource.contentUri(this.location) : isContentUri = true;
  factory AnalysisAudioSource.fromLocation(String location) =>
      location.startsWith('content://')
      ? AnalysisAudioSource.contentUri(location)
      : AnalysisAudioSource.file(location);
  final String location;
  final bool isContentUri;
}

class AudioMetadata {
  const AudioMetadata({
    required this.sourceSampleRate,
    required this.sourceChannels,
    required this.duration,
    required this.mimeType,
  });
  final int sourceSampleRate;
  final int sourceChannels;
  final Duration duration;
  final String mimeType;
}

enum PcmSampleEncoding { float32LittleEndian }

class PcmFormat {
  const PcmFormat({
    this.sampleRate = 44100,
    this.channels = 1,
    this.encoding = PcmSampleEncoding.float32LittleEndian,
  });
  final int sampleRate;
  final int channels;
  final PcmSampleEncoding encoding;
  static const analysis = PcmFormat();
}

/// Owns a temporary headerless PCM file. Dispose after consuming its stream.
class PcmAudioData {
  PcmAudioData({
    required this.file,
    required this.format,
    required this.frames,
    required this.sourceMetadata,
  });
  final File file;
  final PcmFormat format;
  final int frames;
  final AudioMetadata sourceMetadata;
  Duration get duration =>
      Duration(microseconds: (frames * 1000000 / format.sampleRate).round());
  Stream<Uint8List> chunks() =>
      file.openRead(0, null).map((bytes) => Uint8List.fromList(bytes));
  Future<void> dispose() async {
    if (await file.exists()) await file.delete();
  }
}

class DecodedPcmFile {
  const DecodedPcmFile(this.file, this.metadata);
  final File file;
  final AudioMetadata metadata;
}

abstract class AnalysisAudioDecoder {
  Future<DecodedPcmFile> decode(
    AnalysisAudioSource source,
    AnalysisCancellation cancellation,
  );
  Future<void> cancel();
}

/// Native decoders write bounded-buffer, interleaved signed 16-bit LE PCM.
class PlatformAnalysisAudioDecoder implements AnalysisAudioDecoder {
  PlatformAnalysisAudioDecoder({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('sornaz/analysis_audio');
  final MethodChannel _channel;
  @override
  Future<DecodedPcmFile> decode(
    AnalysisAudioSource source,
    AnalysisCancellation cancellation,
  ) async {
    cancellation.throwIfCancelled();
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('decode', {
        'source': source.location,
        'contentUri': source.isContentUri,
      });
      cancellation.throwIfCancelled();
      if (result == null) throw const FormatException('Empty decoder result');
      return DecodedPcmFile(
        File(result['path'] as String),
        AudioMetadata(
          sourceSampleRate: (result['sampleRate'] as num).toInt(),
          sourceChannels: (result['channels'] as num).toInt(),
          duration: Duration(
            microseconds: (result['durationUs'] as num).toInt(),
          ),
          mimeType: result['mime'] as String,
        ),
      );
    } on PlatformException catch (error) {
      final code = switch (error.code) {
        'MISSING_FILE' => AnalysisAudioErrorCode.missingFile,
        'UNSUPPORTED_FORMAT' => AnalysisAudioErrorCode.unsupportedFormat,
        'CANCELLED' => AnalysisAudioErrorCode.cancelled,
        _ => AnalysisAudioErrorCode.decodeFailed,
      };
      throw AnalysisAudioException(code, error.message ?? error.code);
    } on MissingPluginException {
      throw const AnalysisAudioException(
        AnalysisAudioErrorCode.unsupportedFormat,
        'Audio decoding is unavailable on this platform.',
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } on MissingPluginException {
      // The in-flight call will still fail or finish; the caller discards it.
    }
  }
}

class AnalysisAudioPreparer {
  AnalysisAudioPreparer(this.decoder, {Directory? workspace})
    : _workspace = workspace;
  final AnalysisAudioDecoder decoder;
  final Directory? _workspace;

  Future<PcmAudioData> prepare(
    AnalysisAudioSource source, {
    AnalysisCancellation? cancellation,
  }) async {
    final token = cancellation ?? AnalysisCancellation();
    token.throwIfCancelled();
    if (source.location.isEmpty) {
      throw const AnalysisAudioException(
        AnalysisAudioErrorCode.missingFile,
        'Audio source is empty.',
      );
    }
    if (!source.isContentUri && !await File(source.location).exists()) {
      throw AnalysisAudioException(
        AnalysisAudioErrorCode.missingFile,
        'Audio file does not exist: ${source.location}',
      );
    }
    DecodedPcmFile? decoded;
    File? output;
    var completed = false;
    try {
      final future = decoder.decode(source, token).then((value) async {
        if (token.isCancelled) {
          if (await value.file.exists()) await value.file.delete();
          token.throwIfCancelled();
        }
        return value;
      });
      decoded = await Future.any([
        future,
        token.whenCancelled.then<DecodedPcmFile>((_) async {
          await decoder.cancel();
          throw const AnalysisAudioException(
            AnalysisAudioErrorCode.cancelled,
            'Audio preparation was cancelled.',
          );
        }),
      ]);
      token.throwIfCancelled();
      final metadata = decoded!.metadata;
      if (metadata.sourceSampleRate < 8000 ||
          metadata.sourceSampleRate > 192000 ||
          metadata.sourceChannels < 1 ||
          metadata.sourceChannels > 8) {
        throw const AnalysisAudioException(
          AnalysisAudioErrorCode.unsupportedFormat,
          'Invalid decoded sample rate or channel count.',
        );
      }
      final directory = _workspace ?? await getTemporaryDirectory();
      await directory.create(recursive: true);
      output = File(
        '${directory.path}/analysis-${DateTime.now().microsecondsSinceEpoch}.f32le',
      );
      final frames = await convertS16ToAnalysisPcm(
        decoded.file.openRead(),
        output,
        sampleRate: metadata.sourceSampleRate,
        channels: metadata.sourceChannels,
        cancellation: token,
      );
      token.throwIfCancelled();
      completed = true;
      return PcmAudioData(
        file: output,
        format: PcmFormat.analysis,
        frames: frames,
        sourceMetadata: metadata,
      );
    } on AnalysisAudioException {
      rethrow;
    } on FileSystemException catch (error) {
      throw AnalysisAudioException(AnalysisAudioErrorCode.ioFailure, '$error');
    } on FormatException catch (error) {
      throw AnalysisAudioException(
        AnalysisAudioErrorCode.invalidData,
        '$error',
      );
    } finally {
      if (decoded != null && await decoded.file.exists()) {
        await decoded.file.delete();
      }
      if (!completed && output != null && await output.exists()) {
        await output.delete();
      }
    }
  }
}

/// Bounded-memory mono downmix and linear sample-rate conversion. It never
/// rescales amplitude to a peak target. Input is s16le interleaved; output is
/// headerless f32le mono. A channel average avoids summed-signal clipping.
Future<int> convertS16ToAnalysisPcm(
  Stream<List<int>> input,
  File output, {
  required int sampleRate,
  required int channels,
  AnalysisCancellation? cancellation,
}) async {
  if (sampleRate < 8000 ||
      sampleRate > 192000 ||
      channels < 1 ||
      channels > 8) {
    throw const AnalysisAudioException(
      AnalysisAudioErrorCode.unsupportedFormat,
      'Unsupported PCM input format.',
    );
  }
  final token = cancellation ?? AnalysisCancellation();
  final sink = output.openWrite();
  final frameBytes = channels * 2;
  var pending = <int>[];
  var sourceFrame = 0;
  var targetFrame = 0;
  double? previous;
  var last = 0.0;
  var written = 0;
  final frameBuffer = ByteData(4 * 4096);
  var buffered = 0;
  void emit(double value) {
    frameBuffer.setFloat32(buffered * 4, value, Endian.little);
    buffered++;
  }

  void flush() {
    if (buffered == 0) return;
    sink.add(
      Uint8List.fromList(frameBuffer.buffer.asUint8List(0, buffered * 4)),
    );
    written += buffered;
    buffered = 0;
  }

  try {
    await for (final chunk in input) {
      token.throwIfCancelled();
      // Only a partial interleaved frame is retained across chunks.
      final bytes = pending.isEmpty ? chunk : <int>[...pending, ...chunk];
      final complete = bytes.length ~/ frameBytes * frameBytes;
      for (var offset = 0; offset < complete; offset += frameBytes) {
        var mono = 0.0;
        for (var channel = 0; channel < channels; channel++) {
          final at = offset + channel * 2;
          var sample = bytes[at] | bytes[at + 1] << 8;
          if (sample >= 32768) sample -= 65536;
          mono += sample / 32768.0;
        }
        mono /= channels;
        last = mono;
        if (previous != null) {
          while (targetFrame * sampleRate <= sourceFrame * 44100) {
            final position = targetFrame * sampleRate / 44100;
            if (position < sourceFrame - 1) break;
            final fraction = (position - (sourceFrame - 1)).clamp(0.0, 1.0);
            emit(previous + (mono - previous) * fraction);
            targetFrame++;
            if (buffered == 4096) flush();
          }
        }
        previous = mono;
        sourceFrame++;
      }
      pending = bytes.sublist(complete);
      if (buffered > 0) flush();
    }
    token.throwIfCancelled();
    if (pending.isNotEmpty) {
      throw const AnalysisAudioException(
        AnalysisAudioErrorCode.invalidData,
        'Decoded PCM has a partial sample frame.',
      );
    }
    if (sourceFrame == 0) {
      throw const AnalysisAudioException(
        AnalysisAudioErrorCode.invalidData,
        'Decoded PCM is empty.',
      );
    }
    final expected = (sourceFrame * 44100 / sampleRate).round();
    while (targetFrame < expected) {
      emit(last);
      targetFrame++;
      if (buffered == 4096) flush();
    }
    flush();
    await sink.flush();
    await sink.close();
    return written;
  } catch (_) {
    await sink.close();
    if (await output.exists()) await output.delete();
    rethrow;
  }
}
