import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../services/player_settings.dart';

/// Runs on entry, and again when a retained tab becomes active, not on rebuilds.
class MusicPlaybackEntry extends StatefulWidget {
  const MusicPlaybackEntry({
    super.key,
    required this.reason,
    required this.child,
    this.active = true,
  });
  final PlaybackInterruption reason;
  final bool active;
  final Widget child;
  @override
  State<MusicPlaybackEntry> createState() => _MusicPlaybackEntryState();
}

class _MusicPlaybackEntryState extends State<MusicPlaybackEntry> {
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _enter();
  }

  @override
  void didUpdateWidget(MusicPlaybackEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        oldWidget.reason != widget.reason) {
      _enter();
    }
  }

  void _enter() {
    final generation = ++_generation;
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active || generation != _generation) return;
      context.read<AudioPlayerProvider?>()?.interrupt(widget.reason);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
