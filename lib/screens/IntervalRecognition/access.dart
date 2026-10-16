import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'models.dart';
import 'progress.dart';

/// Shared access policy: only the authenticated user ID grants admin access.
class IntervalAccess {
  const IntervalAccess({this.userId});
  factory IntervalAccess.fromSession(AuthSession? session) => IntervalAccess(
    userId: session?.isAuthenticated == true && session!.token!.isNotEmpty
        ? session.user!.id
        : null,
  );
  final int? userId;
  String get scope => userId == null ? 'guest' : 'user.$userId';
  bool get isAdministrator => userId == 1;
  bool canEnter(
    int level,
    IntervalProgress progress, {
    IntervalMusic music = IntervalMusic.western,
  }) =>
      progress.music == music &&
      level >= 1 &&
      level <= music.levelCount &&
      (isAdministrator || progress.isUnlocked(level));
}
