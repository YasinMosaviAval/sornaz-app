import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'analysis_audio.dart';
import 'music_analysis_features.dart';

enum MusicAnalysisErrorCode {
  unsupportedPlatform,
  libraryUnavailable,
  missingSymbol,
  abiMismatch,
  unsupportedFormat,
  missingFile,
  invalidPcm,
  cancelled,
  outOfMemory,
  nativeFailure,
  ioFailure,
}

class MusicAnalysisException implements Exception {
  const MusicAnalysisException(this.code, this.message);
  final MusicAnalysisErrorCode code;
  final String message;

  @override
  String toString() => 'MusicAnalysisException($code): $message';
}

// Mirrors native/music_analysis_dsp.h ABI 1. Keep field order and widths exact.
final class _MaConfig extends ffi.Struct {
  @ffi.Uint32()
  external int structSize;
  @ffi.Uint32()
  external int abiVersion;
  @ffi.Uint32()
  external int sampleRate;
  @ffi.Uint32()
  external int channels;
}

final class _MaFeature extends ffi.Struct {
  @ffi.Uint64()
  external int frameStartSample;
  @ffi.Uint64()
  external int frameValidSamples;
  @ffi.Uint64()
  external int onsetSample;
  @ffi.Double()
  external double timestampSeconds;
  @ffi.Float()
  external double pitchHz;
  @ffi.Float()
  external double pitchConfidence;
  @ffi.Float()
  external double onsetStrength;
  @ffi.Float()
  external double energy;
  @ffi.Float()
  external double rms;
  @ffi.Float()
  external double peakAbs;
  @ffi.Float()
  external double clippingFraction;
  @ffi.Float()
  external double signalQuality;
  @ffi.Uint32()
  external int onsetCandidate;
  @ffi.Uint32()
  external int isSilent;
  @ffi.Uint32()
  external int isPartial;

  RawAudioFeature copy() => RawAudioFeature(
    frameStartSample: frameStartSample,
    frameValidSamples: frameValidSamples,
    onsetSample: onsetSample,
    timestampSeconds: timestampSeconds,
    pitchHz: pitchHz,
    pitchConfidence: pitchConfidence,
    onsetStrength: onsetStrength,
    energy: energy,
    rms: rms,
    peakAbs: peakAbs,
    clippingFraction: clippingFraction,
    signalQuality: signalQuality,
    onsetCandidate: onsetCandidate != 0,
    isSilent: isSilent != 0,
    isPartial: isPartial != 0,
  );
}

typedef _VersionNative = ffi.Uint32 Function();
typedef _VersionDart = int Function();
typedef _CreateNative =
    ffi.Int32 Function(
      ffi.Pointer<_MaConfig>,
      ffi.Int32,
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
    );
typedef _CreateDart =
    int Function(
      ffi.Pointer<_MaConfig>,
      int,
      ffi.Pointer<ffi.Pointer<ffi.Void>>,
    );
typedef _PushNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<ffi.Float>,
      ffi.Size,
      ffi.Pointer<ffi.Size>,
    );
typedef _PushDart =
    int Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<ffi.Float>,
      int,
      ffi.Pointer<ffi.Size>,
    );
typedef _FinalizeNative = ffi.Int32 Function(ffi.Pointer<ffi.Void>);
typedef _FinalizeDart = int Function(ffi.Pointer<ffi.Void>);
typedef _ReadNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<_MaFeature>,
      ffi.Size,
      ffi.Pointer<ffi.Size>,
    );
typedef _ReadDart =
    int Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<_MaFeature>,
      int,
      ffi.Pointer<ffi.Size>,
    );
typedef _DestroyNative = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _DestroyDart = void Function(ffi.Pointer<ffi.Void>);

class _Bindings {
  _Bindings(ffi.DynamicLibrary library)
    : version = library.lookupFunction<_VersionNative, _VersionDart>(
        'ma_abi_version',
      ),
      availableEngines = library.lookupFunction<_VersionNative, _VersionDart>(
        'ma_available_engines',
      ),
      create = library.lookupFunction<_CreateNative, _CreateDart>(
        'ma_create_with_engine',
      ),
      push = library.lookupFunction<_PushNative, _PushDart>('ma_push_samples'),
      finalize = library.lookupFunction<_FinalizeNative, _FinalizeDart>(
        'ma_finalize',
      ),
      read = library.lookupFunction<_ReadNative, _ReadDart>('ma_read_features'),
      destroy = library.lookupFunction<_DestroyNative, _DestroyDart>(
        'ma_destroy',
      );

  final _VersionDart version;
  final _VersionDart availableEngines;
  final _CreateDart create;
  final _PushDart push;
  final _FinalizeDart finalize;
  final _ReadDart read;
  final _DestroyDart destroy;
}

/// Streams copied native features from a Phase 3 PCM file using the open engine.
/// The caller owns [PcmAudioData] and must dispose it after this stream ends.
class MusicAnalysisFfi {
  MusicAnalysisFfi._(this._bindings);

  static const int _abiVersion = 1;
  static const int _openEngine = 1;
  static const int _aubioEngine = 2;
  static const int _maxInputFrames = 4096;
  static const int _readCapacity = 64;
  static const int _queueFull = 4;

  final _Bindings _bindings;

  /// [libraryPath] permits a standalone native test library on a host machine.
  /// Android opens its packaged .so; iOS resolves symbols from the Runner image.
  factory MusicAnalysisFfi.open({String? libraryPath}) {
    ffi.DynamicLibrary library;
    try {
      if (libraryPath != null) {
        library = ffi.DynamicLibrary.open(libraryPath);
      } else if (Platform.isAndroid) {
        library = ffi.DynamicLibrary.open('libmusic_analysis_dsp.so');
      } else if (Platform.isIOS) {
        library = ffi.DynamicLibrary.process();
      } else {
        throw const MusicAnalysisException(
          MusicAnalysisErrorCode.unsupportedPlatform,
          'No default native music-analysis library on this platform.',
        );
      }
    } on ArgumentError catch (error) {
      throw MusicAnalysisException(
        MusicAnalysisErrorCode.libraryUnavailable,
        '$error',
      );
    } on OSError catch (error) {
      throw MusicAnalysisException(
        MusicAnalysisErrorCode.libraryUnavailable,
        '$error',
      );
    }
    late final _Bindings bindings;
    try {
      bindings = _Bindings(library);
    } on ArgumentError catch (error) {
      throw MusicAnalysisException(
        MusicAnalysisErrorCode.missingSymbol,
        '$error',
      );
    }
    if (ffi.sizeOf<_MaConfig>() != 16 ||
        ffi.sizeOf<_MaFeature>() != 80 ||
        bindings.version() != _abiVersion ||
        bindings.availableEngines() & _openEngine == 0) {
      throw const MusicAnalysisException(
        MusicAnalysisErrorCode.abiMismatch,
        'Native music-analysis ABI or feature layout is incompatible.',
      );
    }
    if (const bool.fromEnvironment('dart.vm.product')) {
      if (bindings.availableEngines() & _aubioEngine != 0) {
        throw const MusicAnalysisException(
          MusicAnalysisErrorCode.abiMismatch,
          'Production native library includes the Aubio engine.',
        );
      }
    }
    return MusicAnalysisFfi._(bindings);
  }

  /// The stream is single-use and bounded: at most one file chunk, 4096 native
  /// input samples and 64 output records are resident in this layer at once.
  Stream<RawAudioFeature> extract(
    PcmAudioData audio, {
    AnalysisCancellation? cancellation,
  }) async* {
    void checkCancellation() {
      if (cancellation?.isCancelled == true) {
        throw const MusicAnalysisException(
          MusicAnalysisErrorCode.cancelled,
          'Native audio analysis was cancelled.',
        );
      }
    }

    checkCancellation();
    if (audio.format.sampleRate != 44100 ||
        audio.format.channels != 1 ||
        audio.format.encoding != PcmSampleEncoding.float32LittleEndian ||
        audio.frames < 0 ||
        audio.frames > 0x1fffffffffffffff) {
      throw const MusicAnalysisException(
        MusicAnalysisErrorCode.unsupportedFormat,
        'Expected headerless mono 44,100 Hz float32 little-endian PCM.',
      );
    }
    final expectedBytes = audio.frames * 4;
    int fileBytes;
    try {
      fileBytes = await audio.file.length();
    } on FileSystemException catch (error) {
      throw MusicAnalysisException(
        MusicAnalysisErrorCode.missingFile,
        '$error',
      );
    }
    if (fileBytes != expectedBytes) {
      throw MusicAnalysisException(
        MusicAnalysisErrorCode.invalidPcm,
        'PCM byte length $fileBytes does not match $expectedBytes expected bytes.',
      );
    }

    final arena = Arena();
    ffi.Pointer<ffi.Void> context = ffi.nullptr;
    try {
      final config = arena<_MaConfig>();
      final contextSlot = arena<ffi.Pointer<ffi.Void>>();
      final input = arena<ffi.Float>(_maxInputFrames);
      final features = arena<_MaFeature>(_readCapacity);
      final count = arena<ffi.Size>();
      final consumed = arena<ffi.Size>();
      config.ref
        ..structSize = ffi.sizeOf<_MaConfig>()
        ..abiVersion = _abiVersion
        ..sampleRate = 44100
        ..channels = 1;
      _check(_bindings.create(config, _openEngine, contextSlot), 'create');
      context = contextSlot.value;
      if (context == ffi.nullptr) {
        throw const MusicAnalysisException(
          MusicAnalysisErrorCode.nativeFailure,
          'Native create returned a null context.',
        );
      }
      var byteCount = 0;
      var carry = Uint8List(0);
      try {
        await for (final bytes in audio.file.openRead(0, expectedBytes)) {
          checkCancellation();
          byteCount += bytes.length;
          final data = Uint8List(carry.length + bytes.length)
            ..setRange(0, carry.length, carry)
            ..setRange(carry.length, carry.length + bytes.length, bytes);
          final completeBytes = data.length & ~3;
          final values = ByteData.sublistView(data, 0, completeBytes);
          final sampleCount = completeBytes ~/ 4;
          for (var start = 0; start < sampleCount; start += _maxInputFrames) {
            checkCancellation();
            final amount = sampleCount - start < _maxInputFrames
                ? sampleCount - start
                : _maxInputFrames;
            for (var i = 0; i < amount; i++) {
              input[i] = values.getFloat32((start + i) * 4, Endian.little);
            }
            var offset = 0;
            while (offset < amount) {
              checkCancellation();
              final status = _bindings.push(
                context,
                input + offset,
                amount - offset,
                consumed,
              );
              if (consumed.value > amount - offset) {
                throw const MusicAnalysisException(
                  MusicAnalysisErrorCode.nativeFailure,
                  'Native push reported an invalid consumed count.',
                );
              }
              offset += consumed.value;
              if (status != 0 && status != _queueFull) {
                _check(status, 'push');
              }
              var drained = 0;
              while (true) {
                final batch = _readBatch(context, features, count);
                if (batch.isEmpty) break;
                drained += batch.length;
                for (final feature in batch) {
                  checkCancellation();
                  yield feature;
                }
              }
              if (status == _queueFull && drained == 0) {
                throw const MusicAnalysisException(
                  MusicAnalysisErrorCode.nativeFailure,
                  'Native queue is full but no feature could be drained.',
                );
              }
              if (status == 0 && consumed.value == 0) {
                throw const MusicAnalysisException(
                  MusicAnalysisErrorCode.nativeFailure,
                  'Native push made no progress.',
                );
              }
            }
          }
          carry = Uint8List.fromList(data.sublist(completeBytes));
        }
      } on FileSystemException catch (error) {
        throw MusicAnalysisException(
          MusicAnalysisErrorCode.ioFailure,
          '$error',
        );
      }
      checkCancellation();
      if (byteCount != expectedBytes || carry.isNotEmpty) {
        throw const MusicAnalysisException(
          MusicAnalysisErrorCode.invalidPcm,
          'PCM file ended with a truncated or incomplete float32 sample.',
        );
      }
      while (true) {
        checkCancellation();
        final status = _bindings.finalize(context);
        if (status != 0 && status != _queueFull) _check(status, 'finalize');
        var drained = 0;
        while (true) {
          final batch = _readBatch(context, features, count);
          if (batch.isEmpty) break;
          drained += batch.length;
          for (final feature in batch) {
            checkCancellation();
            yield feature;
          }
        }
        if (status == 0) break;
        if (drained == 0) {
          throw const MusicAnalysisException(
            MusicAnalysisErrorCode.nativeFailure,
            'Native finalize could not drain the feature queue.',
          );
        }
      }
    } on OutOfMemoryError {
      throw const MusicAnalysisException(
        MusicAnalysisErrorCode.outOfMemory,
        'Dart could not allocate the native analysis buffers.',
      );
    } finally {
      if (context != ffi.nullptr) _bindings.destroy(context);
      arena.releaseAll();
    }
  }

  List<RawAudioFeature> _readBatch(
    ffi.Pointer<ffi.Void> context,
    ffi.Pointer<_MaFeature> features,
    ffi.Pointer<ffi.Size> count,
  ) {
    _check(_bindings.read(context, features, _readCapacity, count), 'read');
    if (count.value > _readCapacity) {
      throw const MusicAnalysisException(
        MusicAnalysisErrorCode.nativeFailure,
        'Native read exceeded the supplied feature capacity.',
      );
    }
    return List<RawAudioFeature>.generate(
      count.value,
      (index) => features[index].copy(),
      growable: false,
    );
  }

  void _check(int status, String operation) {
    if (status == 0) return;
    final code = switch (status) {
      1 => MusicAnalysisErrorCode.nativeFailure,
      2 => MusicAnalysisErrorCode.unsupportedFormat,
      3 => MusicAnalysisErrorCode.outOfMemory,
      5 => MusicAnalysisErrorCode.nativeFailure,
      6 => MusicAnalysisErrorCode.invalidPcm,
      _ => MusicAnalysisErrorCode.nativeFailure,
    };
    throw MusicAnalysisException(
      code,
      'Native $operation failed (status $status).',
    );
  }
}
