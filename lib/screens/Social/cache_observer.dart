import 'dart:async';
import 'package:flutter/widgets.dart';
import 'course_cache.dart';

mixin CourseCacheObserver<T extends StatefulWidget> on State<T> {
  Future<void> load();
  Timer? _refreshTimer;
  void _changed() {
    if (mounted) unawaited(load());
  }

  @override
  void initState() {
    super.initState();
    CourseCache.revisions.addListener(_changed);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _changed(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    CourseCache.revisions.removeListener(_changed);
    super.dispose();
  }
}
