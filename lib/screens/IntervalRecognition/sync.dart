import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Social/social_api.dart';
import 'models.dart';
import 'progress.dart';
import 'results.dart';

class IntervalResultsApi {
  IntervalResultsApi({required this.token, http.Client? client})
    : client = client ?? http.Client();
  final String? Function() token;
  final http.Client client;
  Future<Json> _request({
    Map<String, dynamic>? payload,
    required IntervalMusic music,
    String path = '/practice/interval-results',
  }) async {
    final credential = token();
    if (credential == null || credential.isEmpty)
      throw const SocialException('نشست معتبر نیست.', 401);
    final uri = Uri.parse(
      '${SocialApi.base}$path',
    ).replace(queryParameters: payload == null ? {'music': music.name} : null);
    final headers = {
      'Authorization': 'Bearer $credential',
      'Accept': 'application/json',
      'Accept-Language': SocialApi.locale,
    };
    final request = http.Request(payload == null ? 'GET' : 'POST', uri)
      ..followRedirects = false
      ..headers.addAll(headers);
    if (payload != null) request.bodyFields = {'payload': jsonEncode(payload)};
    final response = await (() async => http.Response.fromStream(
      await client.send(request),
    ))().timeout(const Duration(seconds: 15));
    if (token() != credential)
      throw const SocialException('حساب کاربری تغییر کرده است.', 401);
    if (response.statusCode != 200)
      throw SocialException('همگام‌سازی نتایج انجام نشد.', response.statusCode);
    final body = optionalObject(jsonDecode(utf8.decode(response.bodyBytes)));
    final envelope = body['status'] != null
        ? optionalObject(body['data'])
        : body;
    if (envelope['success'] != true || envelope['data'] is! Map)
      throw const SocialException('پاسخ سرویس معتبر نیست.');
    return optionalObject(envelope['data']);
  }

  Future<Json> progress(IntervalMusic music) => _request(music: music);
  Future<Json> upload(IntervalMusic music, Json payload) =>
      _request(music: music, payload: payload);
  Future<Json> importLegacy(IntervalMusic music, Set<int> levels) => _request(
    music: music,
    path: '/practice/interval-progress/import',
    payload: {
      'music': music.name,
      'version': 1,
      'levels': levels.toList()..sort(),
    },
  );
  void dispose() => client.close();
}

/// Upload immutable ordered batches; timeouts leave the local queue intact.
class IntervalResultsSync {
  IntervalResultsSync({
    required this.api,
    required this.journal,
    required this.store,
  });
  final IntervalResultsApi api;
  final IntervalResultJournal journal;
  final IntervalProgressStore store;
  Future<void>? _running;
  DateTime? _last;
  bool hasError = false;
  bool _disposed = false;
  final _imported = <int>{};
  Future<void> sync({bool force = false}) {
    if (_disposed) return Future.value();
    if (_running != null)
      return force ? _running!.then((_) => sync(force: true)) : _running!;
    if (!force &&
        _last != null &&
        DateTime.now().difference(_last!) < const Duration(seconds: 5))
      return Future.value();
    final task = _perform();
    _running = task;
    return task.whenComplete(() => _running = null);
  }

  Future<void> _perform() async {
    _last = DateTime.now();
    try {
      final progress = await store.load();
      final legacy = progress.stars.keys.toSet().difference(_imported);
      if (legacy.isNotEmpty) {
        await api.importLegacy(journal.music, legacy);
        _imported.addAll(legacy);
      }
      for (final run in await journal.runs(pendingOnly: true)) {
        var sequence = run['syncedSequence'] as int;
        final offset = run['answerOffset'] as int;
        final answers = List<dynamic>.from(run['answers'] as List);
        final total = offset + answers.length;
        while (!_disposed &&
            (sequence < total ||
                run['closed'] == true && run['syncedClosed'] != true)) {
          final chunk = answers.skip(sequence - offset).take(100).toList();
          final closed =
              run['closed'] == true && sequence + chunk.length == total;
          final response = await api.upload(journal.music, {
            'runId': run['id'],
            'music': journal.music.name,
            'level': run['level'],
            'version': 1,
            'mode': run['mode'],
            'answers': chunk,
            'closed': closed,
          });
          final expected = sequence + chunk.length;
          if (response['acceptedThrough'] != expected)
            throw const SocialException('تأیید ثبت نتیجه معتبر نیست.');
          if (_disposed) return;
          await journal.acknowledge('${run['id']}', expected, closed);
          sequence = expected;
          if (closed || sequence == total) break;
        }
      }
      if (_disposed) return;
      final response = await api.progress(journal.music);
      if (_disposed) return;
      final awards = <String, int>{
        for (final row in objects(response['awards'] ?? []))
          if (row['level'] is int) '${row['runId']}': row['level'] as int,
      };
      final legacyStars = <int, int>{
        for (final row in objects(response['legacyStars'] ?? []))
          if (row['level'] is int && row['stars'] == 1) row['level'] as int: 1,
      };
      final local = await store.load();
      await store.save(
        local.merge(
          IntervalProgress(
            music: journal.music,
            stars: legacyStars,
            awards: awards,
          ),
        ),
      );
      hasError = false;
    } catch (_) {
      // Local persistence succeeds independently of credentials or deployment.
      hasError = true;
    }
  }

  void dispose() {
    _disposed = true;
    api.dispose();
  }
}
