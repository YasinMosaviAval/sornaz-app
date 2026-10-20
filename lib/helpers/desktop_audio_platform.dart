import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'app_platform.dart';

/// Reuse the same Windows engine as the music player for finite previews,
/// recordings and metronome assets. Android keeps its existing implementation.
class DesktopAudioPlatform extends JustAudioPlatform {
  DesktopAudioPlatform({audio.AudioPlayer Function()? createPlayer})
    : _createPlayer = createPlayer ?? audio.AudioPlayer.new;
  final audio.AudioPlayer Function() _createPlayer;
  final _players = <String, _DesktopAudioPlayer>{};
  static void install() {
    if (AppPlatform.isWindows)
      JustAudioPlatform.instance = DesktopAudioPlatform();
  }

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      _players.putIfAbsent(
        request.id,
        () => _DesktopAudioPlayer(request.id, _createPlayer()),
      );
  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    await _players.remove(request.id)?.dispose(DisposeRequest());
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    final players = _players.values.toList();
    _players.clear();
    for (final player in players) {
      await player.dispose(DisposeRequest());
    }
    return DisposeAllPlayersResponse();
  }
}

class _DesktopAudioPlayer extends AudioPlayerPlatform {
  _DesktopAudioPlayer(super.id, this._player) {
    _subscriptions.add(
      _player.onDurationChanged.listen((value) {
        _fullDuration = value;
        if (!_loading) _publish();
      }),
    );
    _subscriptions.add(
      _player.onPlayerComplete.listen((_) {
        if (!_loading) unawaited(_finish().catchError(_error));
      }),
    );
  }
  final audio.AudioPlayer _player;
  final _events = StreamController<PlaybackEventMessage>.broadcast();
  final _subscriptions = <StreamSubscription>[];
  ProcessingStateMessage _state = ProcessingStateMessage.idle;
  Duration? _fullDuration, _end;
  Duration _start = Duration.zero, _position = Duration.zero;
  LoopModeMessage _loop = LoopModeMessage.off;
  bool _closed = false,
      _loading = false,
      _playing = false,
      _polling = false,
      _finishing = false;
  double _speed = 1;
  int _generation = 0;
  Timer? _poll, _clipTimer;
  Completer<PlayResponse>? _playDone;
  Duration? get _duration {
    final end = _end ?? _fullDuration;
    return end == null
        ? null
        : Duration(
            microseconds: (end - _start).inMicroseconds.clamp(
              0,
              end.inMicroseconds,
            ),
          );
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;
  void _publish() {
    if (_closed) return;
    _events.add(
      PlaybackEventMessage(
        processingState: _state,
        updateTime: DateTime.now(),
        updatePosition: _position,
        bufferedPosition: _duration ?? _position,
        duration: _duration,
        icyMetadata: null,
        currentIndex: _state == ProcessingStateMessage.idle ? null : 0,
        androidAudioSessionId: null,
      ),
    );
  }

  void _error(Object error) {
    if (!_closed) _events.addError(error);
  }

  void _endPlay() {
    _poll?.cancel();
    _clipTimer?.cancel();
    final done = _playDone;
    _playDone = null;
    if (done != null && !done.isCompleted) done.complete(PlayResponse());
  }

  void _schedule() {
    _poll?.cancel();
    _clipTimer?.cancel();
    if (!_playing || _closed || _state == ProcessingStateMessage.completed)
      return;
    _poll = Timer.periodic(const Duration(milliseconds: 40), (_) async {
      if (_polling || _closed || !_playing) return;
      _polling = true;
      try {
        final value = await _player.getCurrentPosition();
        if (_closed || !_playing) return;
        if (value != null) {
          _position = Duration(
            microseconds: (value - _start).inMicroseconds.clamp(
              0,
              _duration?.inMicroseconds ?? 1 << 62,
            ),
          );
          _publish();
          if (_end != null && value >= _end!) await _finish();
        }
      } catch (error) {
        _error(error);
      } finally {
        _polling = false;
      }
    });
    if (_end != null && _duration != null) {
      final remaining = ((_duration! - _position).inMicroseconds / _speed)
          .round();
      _clipTimer = Timer(
        Duration(microseconds: remaining.clamp(0, 1 << 62)),
        () => unawaited(_finish().catchError(_error)),
      );
    }
  }

  Future<void> _finish() async {
    if (_closed ||
        _loading ||
        _finishing ||
        _state == ProcessingStateMessage.completed)
      return;
    _finishing = true;
    try {
      if (_loop != LoopModeMessage.off && _playing) {
        await _player.seek(_start);
        _position = Duration.zero;
        await _player.resume();
        _state = ProcessingStateMessage.ready;
        _schedule();
      } else {
        _endPlay();
        await _player.pause();
        _position = _duration ?? _position;
        _state = ProcessingStateMessage.completed;
      }
      _publish();
    } finally {
      _finishing = false;
    }
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final generation = ++_generation;
    _loading = true;
    _poll?.cancel();
    _clipTimer?.cancel();
    _state = ProcessingStateMessage.loading;
    _fullDuration = null;
    _start = Duration.zero;
    _end = null;
    _position = Duration.zero;
    _publish();
    try {
      var source = request.audioSourceMessage;
      if (source is ClippingAudioSourceMessage) {
        _start = source.start ?? Duration.zero;
        _end = source.end;
        source = source.child;
      }
      if (source is! UriAudioSourceMessage)
        throw UnsupportedError('Unsupported desktop audio source');
      final uri = Uri.parse(source.uri);
      final audio.Source nativeSource;
      if (uri.scheme == 'file') {
        nativeSource = audio.DeviceFileSource(uri.toFilePath());
      } else if (uri.scheme == 'asset') {
        nativeSource = audio.AssetSource(
          uri.path.replaceFirst(RegExp(r'^/?assets/'), ''),
        );
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        nativeSource = audio.UrlSource(source.uri);
      } else {
        throw UnsupportedError('Unsupported desktop audio URI');
      }
      await _player.stop();
      await _player.setReleaseMode(audio.ReleaseMode.stop);
      await _player.setSource(nativeSource);
      if (_closed || generation != _generation)
        throw StateError('Audio load interrupted');
      _fullDuration = await _player.getDuration();
      if ((_fullDuration == null || _fullDuration == Duration.zero) &&
          uri.scheme != 'http' &&
          uri.scheme != 'https') {
        _fullDuration = await _player.onDurationChanged
            .firstWhere((value) => value > Duration.zero)
            .timeout(const Duration(seconds: 10));
      }
      if (_fullDuration != null && _end != null && _end! > _fullDuration!)
        _end = _fullDuration;
      _position = request.initialPosition ?? Duration.zero;
      await _player.seek(_start + _position);
      await _player.setPlaybackRate(_speed);
      _loading = false;
      _state = ProcessingStateMessage.ready;
      if (_playing) await _player.resume();
      _publish();
      _schedule();
      return LoadResponse(duration: _duration);
    } catch (error) {
      if (!_closed && generation == _generation) {
        _loading = false;
        _state = ProcessingStateMessage.idle;
        _playing = false;
        _endPlay();
        _publish();
      }
      rethrow;
    }
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    if (_playDone != null) return _playDone!.future;
    final done = Completer<PlayResponse>();
    _playDone = done;
    _playing = true;
    if (_loading || _state == ProcessingStateMessage.idle) return done.future;
    if (_state == ProcessingStateMessage.completed) {
      await _player.seek(_start);
      _position = Duration.zero;
    }
    _state = ProcessingStateMessage.ready;
    _playing = true;
    try {
      await _player.resume();
      _publish();
      _schedule();
    } catch (_) {
      _playing = false;
      _endPlay();
      rethrow;
    }
    return done.future;
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    _playing = false;
    _endPlay();
    await _player.pause();
    _publish();
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    if (request.index != null && request.index != 0)
      throw RangeError('Single source index');
    _position = request.position ?? Duration.zero;
    if (_position < Duration.zero) _position = Duration.zero;
    if (_duration != null && _position > _duration!) _position = _duration!;
    final restart = _state == ProcessingStateMessage.completed && _playing;
    await _player.seek(_start + _position);
    if (_state == ProcessingStateMessage.completed)
      _state = ProcessingStateMessage.ready;
    if (restart) await _player.resume();
    _publish();
    _schedule();
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    await _player.setVolume(request.volume);
    return SetVolumeResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    _speed = request.speed;
    await _player.setPlaybackRate(_speed);
    _schedule();
    return SetSpeedResponse();
  }

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async {
    if (request.pitch != 1)
      throw UnsupportedError('Independent pitch adjustment is unavailable');
    return SetPitchResponse();
  }

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async {
    if (request.enabled)
      throw UnsupportedError('Silence skipping is unavailable');
    return SetSkipSilenceResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    _loop = request.loopMode;
    return SetLoopModeResponse();
  }

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();
  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async => SetShuffleOrderResponse();
  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse();
  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
  setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async => SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();
  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async => SetPreferredPeakBitRateResponse();
  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
    SetAllowsExternalPlaybackRequest request,
  ) async => SetAllowsExternalPlaybackResponse();
  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    if (_closed) return DisposeResponse();
    _closed = true;
    _generation++;
    _endPlay();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _events.close();
    return DisposeResponse();
  }
}
