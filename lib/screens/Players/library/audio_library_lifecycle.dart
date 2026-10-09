import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';

import 'audio_library_manager.dart';
import 'device_audio_scan.dart';

class AudioLibraryLifecycle extends StatefulWidget {
  const AudioLibraryLifecycle({
    super.key,
    required this.library,
    required this.folders,
    required this.child,
  });

  final AudioLibraryManager library;
  final FolderNavigatorProvider folders;
  final Widget child;

  @override
  State<AudioLibraryLifecycle> createState() => _AudioLibraryLifecycleState();
}

class _AudioLibraryLifecycleState extends State<AudioLibraryLifecycle>
    with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
  }

  Future<void> _refresh() async {
    try {
      await refreshDeviceAudioLibrary(
        library: widget.library,
        folders: widget.folders,
      );
    } catch (_) {
      // A later foreground entry or an explicit rescan can retry.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      unawaited(_refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
