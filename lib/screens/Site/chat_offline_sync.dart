import 'dart:async';
import '../Social/social_api.dart';
import 'chat_cache.dart';
import 'chat_media.dart';
import 'panel_api.dart';

/// One history request at a time; background caching never marks messages read.
class ChatOfflineSync {
  ChatOfflineSync(this.api);
  final PanelApi api;
  Timer? timer;
  bool disposed = false, running = false;
  List<Json> conversations = [];
  int conversation = 0, cursor = 0;
  final collected = <int, Json>{};
  final media = <Json>[];
  void start(List<Json> rows) {
    if (running || disposed) return;
    conversations = List.of(rows);
    conversation = 0;
    cursor = 0;
    collected.clear();
    media.clear();
    running = rows.isNotEmpty;
    schedule();
  }

  void schedule() {
    if (!running || disposed) return;
    timer = Timer(const Duration(seconds: 1), step);
  }

  Future<void> step() async {
    try {
      if (disposed) {
        running = false;
        return;
      }
      if (conversation >= conversations.length) {
        if (media.isEmpty) {
          running = false;
          return;
        }
        final row = media.removeAt(0);
        try {
          if (optionalObject(row['file']).isNotEmpty)
            await ChatFiles.open(api, '${row['id']}');
          final ref = optionalObject(row['reference']);
          final expires = DateTime.tryParse('${ref['expiresAt']}');
          if (ref['available'] == true &&
              (ref['owner'] == true ||
                  expires == null ||
                  DateTime.now().isBefore(expires))) {
            if (ref['media'] != null) await ChatFiles.reference(api, ref);
            final social = SocialApi(api.token);
            try {
              await social.get('/posts/${ref['id']}');
            } finally {
              social.dispose();
            }
          }
        } on SocialException catch (e) {
          if (ChatCache.mayUseOffline(e)) rethrow;
        }
        schedule();
        return;
      }
      final catalog = await api.get('');
      if (disposed || catalog['_offline'] == true) {
        running = false;
        return;
      }
      final id = '${conversations[conversation]['id']}';
      final data = await api.get('/chat/messages', {
        'id': id,
        'after': '$cursor',
        'read': '0',
      });
      if (disposed || data['_offline'] == true) {
        running = false;
        return;
      }
      final rows = objects(data['messages'] ?? []);
      for (final row in rows) {
        collected[number(row['id'])] = row;
        if (optionalObject(row['file']).isNotEmpty ||
            optionalObject(row['reference']).isNotEmpty)
          media.add(row);
      }
      final next = rows.isEmpty ? cursor : number(rows.last['id']);
      final complete =
          rows.length < (cursor == 0 ? 200 : 100) || next <= cursor;
      final snapshot = <int, Json>{};
      if (!complete) {
        final old = await ChatCache.read(api.token, 'conversation:$id');
        if (old is List)
          for (final row in objects(old)) {
            if (number(row['id']) > next) snapshot[number(row['id'])] = row;
          }
      }
      snapshot.addAll(collected);
      final saved = snapshot.values.toList()
        ..sort((a, b) => number(a['id']).compareTo(number(b['id'])));
      await ChatCache.write(api.token, 'conversation:$id', saved);
      if (complete) {
        conversation++;
        cursor = 0;
        collected.clear();
      } else {
        cursor = next;
      }
      if (conversation >= conversations.length && media.isEmpty)
        running = false;
      schedule();
    } catch (_) {
      running = false;
    }
  }

  void dispose() {
    disposed = true;
    timer?.cancel();
  }
}
