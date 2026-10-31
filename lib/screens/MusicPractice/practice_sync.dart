import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'practice_repository.dart';

/// Synchronizes the account's durable catalog independently of the selected tab.
class MusicPracticeSync with WidgetsBindingObserver {
  MusicPracticeSync(this.repository, {Stream<bool>? connections}) {
    WidgetsBinding.instance.addObserver(this);
    subscription =
        (connections ??
                const EventChannel(
                  'sornaz/network',
                ).receiveBroadcastStream().map((event) => event == true))
            .distinct()
            .listen((online) {
              if (online) unawaited(refresh());
            }, onError: (Object _) {});
    timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!busy &&
          (lastRefresh == null ||
              repository.offline ||
              DateTime.now().difference(lastRefresh!).inSeconds >= 60) &&
          (WidgetsBinding.instance.lifecycleState == null ||
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed)) {
        unawaited(refresh());
      }
    });
    unawaited(refresh());
  }
  final MusicPracticeRepository repository;
  static final updates = StreamController<int?>.broadcast();
  StreamSubscription<bool>? subscription;
  Timer? timer;
  bool disposed = false, busy = false, pending = false;
  DateTime? lastRefresh;
  bool legacySynced = false;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  Future<void> refresh() async {
    if (disposed) return;
    if (busy) {
      pending = true;
      return;
    }
    busy = true;
    try {
      await repository.catalog();
      if (disposed) return;
      lastRefresh = DateTime.now();
      if (!repository.offline && repository.userId != null) {
        if (!legacySynced) {
          legacySynced = true;
          unawaited(_uploadLegacy());
        }
        try {
          await repository.upload();
        } catch (_) {}
      }
      if (repository.offline) legacySynced = false;
      await repository.progress();
      if (!disposed && !repository.offline) updates.add(repository.userId);
    } catch (_) {
      // Network failure leaves the last complete catalog and answer journal intact.
    } finally {
      busy = false;
      if (pending && !disposed) {
        pending = false;
        unawaited(refresh());
      }
    }
  }

  void dispose() {
    disposed = true;
    timer?.cancel();
    unawaited(subscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    repository.dispose();
  }

  Future<void> _uploadLegacy() async {
    try {
      await repository.uploadLegacy();
      if (!disposed) {
        await repository.progress();
        if (!disposed) updates.add(repository.userId);
      }
    } catch (_) {
      legacySynced = false;
    }
  }
}
