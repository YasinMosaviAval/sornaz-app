import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Social/social_api.dart';
import '../IntervalRecognition/models.dart';
import '../IntervalRecognition/progress.dart';
import '../IntervalRecognition/results.dart';
import '../IntervalRecognition/sync.dart';

typedef PracticeJson = Map<String, dynamic>;

class MusicPracticeRepository {
  MusicPracticeRepository({
    required this.userId,
    required this.token,
    http.Client? client,
  }) : client = client ?? http.Client();
  final int? userId;
  final String? Function() token;
  final http.Client client;
  String get scope => 'user.${userId ?? 0}';
  bool offline = false;
  Object? lastSyncError;
  bool disposed = false;
  static Future<void> _queue = Future.value();
  Future<void>? _syncing;
  Future<Box<String>> get box => Hive.openBox<String>('music_practice_v1');
  Future<T> locked<T>(Future<T> Function() work) {
    final task = _queue.then((_) => work());
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<PracticeJson> request(String path, [PracticeJson? payload]) async {
    final credential = token();
    if (disposed) throw const SocialException('صفحه بسته شده است.');
    final uri = Uri.parse('${SocialApi.base}/music-practice/$path');
    final request = http.Request(payload == null ? 'GET' : 'POST', uri)
      ..followRedirects = false
      ..headers.addAll({
        'Accept': 'application/json',
        'Accept-Language': SocialApi.locale,
        if (credential != null) 'Authorization': 'Bearer $credential',
      });
    if (payload != null) request.bodyFields = {'payload': jsonEncode(payload)};
    final response = await (() async => http.Response.fromStream(
      await client.send(request),
    ))().timeout(const Duration(seconds: 20));
    if (disposed || token() != credential) {
      throw const SocialException('حساب کاربری تغییر کرده است.', 401);
    }
    Map body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    } catch (_) {
      throw SocialException(
        'پاسخ سرور آزمون‌ها معتبر نیست (${response.statusCode}).',
        response.statusCode,
      );
    }
    final envelope = Map<String, dynamic>.from(
      body['data'] is Map ? body['data'] as Map : body,
    );
    if (response.statusCode != 200 || envelope['success'] == false) {
      throw SocialException(
        envelope['message']?.toString() ?? 'درخواست انجام نشد.',
        response.statusCode,
      );
    }
    return Map<String, dynamic>.from(
      envelope['data'] is Map ? envelope['data'] as Map : envelope,
    );
  }

  Future<PracticeJson> catalog({
    bool manage = false,
    bool allowCached = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await request('catalog${manage ? '?manage=1' : ''}');
      if (data['viewerId'] != (userId ?? 0)) {
        throw const SocialException('حساب کاربری تغییر کرده است.', 401);
      }
      _validateCatalog(data);
      if (!manage) {
        final archive = await box;
        final versions = <String, String>{};
        for (final exam in data['exams'] as List? ?? []) {
          if (exam['access'] == true && exam['config'] is Map) {
            versions['$scope.definition.${exam['id']}.${exam['version']}'] =
                jsonEncode(exam);
          }
        }
        if (versions.isNotEmpty) await archive.putAll(versions);
        await prefs.setString(
          'music.practice.catalog.$scope',
          jsonEncode(data),
        );
      }
      offline = false;
      lastSyncError = null;
      return manage ? data : (await cachedCatalog())!;
    } catch (e) {
      lastSyncError = e;
      if (!allowCached ||
          manage ||
          e is SocialException && [401, 403].contains(e.status)) {
        if (e is SocialException && [401, 403].contains(e.status)) {
          await prefs.remove('music.practice.catalog.$scope');
        }
        rethrow;
      }
      final saved = await cachedCatalog();
      if (saved == null ||
          (saved['nodes'] as List).isEmpty &&
              (saved['exams'] as List).isEmpty) {
        rethrow;
      }
      offline = true;
      return saved;
    }
  }

  Future<PracticeJson?> cachedCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('music.practice.catalog.$scope');
    if (saved == null) return null;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(saved) as Map);
      _validateCatalog(data);
      return data;
    } catch (_) {
      return null;
    }
  }

  void _validateCatalog(PracticeJson data) {
    if (data['nodes'] is! List ||
        data['exams'] is! List ||
        data['viewerId'] != (userId ?? 0)) {
      throw const SocialException(
        'ساختار فهرست آزمون‌های دریافتی معتبر نیست.',
        502,
      );
    }
    for (final row in [...data['nodes'] as List, ...data['exams'] as List]) {
      if (row is! Map || row['id'] is! int) {
        throw const SocialException(
          'ساختار فهرست آزمون‌های دریافتی معتبر نیست.',
          502,
        );
      }
    }
  }

  Future<List<PracticeJson>> progress({bool refresh = true}) async {
    final prefs = await SharedPreferences.getInstance();
    List<PracticeJson> result = [];
    if (userId != null) {
      try {
        if (!refresh) throw const SocialException('Cached progress');
        final data = await request('progress');
        result = (data['progress'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await prefs.setString(
          'music.practice.progress.$scope',
          jsonEncode(result),
        );
      } catch (e) {
        if (e is SocialException && [401, 403].contains(e.status)) rethrow;
        result =
            (jsonDecode(
                      prefs.getString('music.practice.progress.$scope') ?? '[]',
                    )
                    as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
      }
    }
    await _mergeLegacy(result);
    for (final run in await runs()) {
      if (run['passed'] != true) continue;
      final exam = Map<String, dynamic>.from(run['exam'] as Map);
      var matches = result.where(
        (p) => p['examId'] == exam['id'] && p['version'] == exam['version'],
      );
      final p = matches.isEmpty
          ? <String, dynamic>{
              'examId': exam['id'],
              'version': exam['version'],
              'completedStages': <dynamic>[],
            }
          : matches.first;
      if (matches.isEmpty) result.add(p);
      final stages = List<dynamic>.from(p['completedStages'] as List);
      if (!stages.contains(run['stage'])) stages.add(run['stage']);
      p['completedStages'] = stages;
      p['stars'] = (stages.length * 5 / (exam['stageCount'] as int))
          .floor()
          .clamp(0, 5);
    }
    return result;
  }

  Future<void> _mergeLegacy(List<PracticeJson> result) async {
    final saved = await cachedCatalog();
    if (saved == null) return;
    final branches = <String, IntervalProgress>{};
    for (final music in IntervalMusic.values) {
      branches[music.name] = await IntervalProgressRepository(
        userId: userId,
        music: music,
        journal: IntervalResultJournal(userId: userId, music: music),
      ).load();
    }
    for (final exam in saved['exams'] as List? ?? []) {
      if (exam['version'] != 1 || exam['legacyKey'] is! String) continue;
      final parts = (exam['legacyKey'] as String).split(':');
      if (parts.length != 2) continue;
      final level = int.tryParse(parts[1]);
      if (level == null) continue;
      final count = branches[parts[0]]?.starsFor(level) ?? 0;
      if (count == 0) continue;
      final matches = result.where(
        (p) => p['examId'] == exam['id'] && p['version'] == 1,
      );
      final p = matches.isEmpty
          ? <String, dynamic>{
              'examId': exam['id'],
              'version': 1,
              'completedStages': <dynamic>[],
            }
          : matches.first;
      if (matches.isEmpty) result.add(p);
      final stages = List<dynamic>.from(p['completedStages'] as List);
      for (
        var stage = 1;
        stage <= count && stage <= (exam['stageCount'] as int);
        stage++
      ) {
        if (!stages.contains(stage)) stages.add(stage);
      }
      p['completedStages'] = stages;
      p['stars'] = (stages.length * 5 / (exam['stageCount'] as int))
          .floor()
          .clamp(0, 5);
    }
  }

  Future<void> uploadLegacy() async {
    if (userId == null) return;
    for (final music in IntervalMusic.values) {
      final journal = IntervalResultJournal(userId: userId, music: music),
          store = IntervalProgressRepository(
            userId: userId,
            music: music,
            journal: journal,
          );
      final sync = IntervalResultsSync(
        api: IntervalResultsApi(token: token),
        journal: journal,
        store: store,
      );
      try {
        await sync.sync(force: true);
      } finally {
        sync.dispose();
      }
    }
  }

  Future<List<PracticeJson>> runs() => locked(() async {
    final b = await box, result = <PracticeJson>[];
    for (final key in b.keys.whereType<String>().where(
      (k) => k.startsWith('$scope.run.') && !k.contains('.answer.'),
    )) {
      result.add(await _restore(b, key));
    }
    result.sort((a, b) {
      final ea = Map<String, dynamic>.from(a['exam'] as Map),
          eb = Map<String, dynamic>.from(b['exam'] as Map);
      for (final key in ['id', 'version']) {
        final d = (ea[key] as int).compareTo(eb[key] as int);
        if (d != 0) return d;
      }
      final stage = (a['stage'] as int).compareTo(b['stage'] as int);
      return stage != 0
          ? stage
          : (a['startedAt'] as String).compareTo(b['startedAt'] as String);
    });
    return result;
  });
  Future<PracticeJson> _restore(Box<String> b, String key) async {
    final run = Map<String, dynamic>.from(jsonDecode(b.get(key)!) as Map);
    var sequence = run['answerCount'] as int;
    while (b.containsKey('$key.answer.${sequence + 1}')) {
      final answer = Map<String, dynamic>.from(
        jsonDecode(b.get('$key.answer.${++sequence}')!) as Map,
      );
      _apply(run, answer);
    }
    await b.put(key, jsonEncode(run));
    return run;
  }

  void _apply(PracticeJson run, PracticeJson answer) {
    final exam = Map<String, dynamic>.from(run['exam'] as Map),
        config = Map<String, dynamic>.from(exam['config'] as Map);
    final expected = config['kind'] == 'interval'
        ? answer['expected']
        : (config['questions'] as List)[answer['question'] as int]['correct'];
    run['answerCount'] = answer['sequence'];
    run['streak'] = expected == answer['selected']
        ? (run['streak'] as int) + 1
        : 0;
    run['passed'] = (run['streak'] as int) >= (exam['requiredWins'] as int);
    if (run['passed'] == true) run['closed'] = true;
  }

  Future<PracticeJson> append({
    required String id,
    required PracticeJson exam,
    required int stage,
    required PracticeJson answer,
  }) => locked(() async {
    final b = await box, key = '$scope.run.$id';
    var run = b.containsKey(key)
        ? await _restore(b, key)
        : <String, dynamic>{
            'id': id,
            'exam': exam,
            'stage': stage,
            'answerCount': 0,
            'streak': 0,
            'passed': false,
            'closed': false,
            'ack': 0,
            'closedAck': false,
            'startedAt': answer['answeredAt'],
          };
    if (run['closed'] == true ||
        answer['sequence'] != (run['answerCount'] as int) + 1) {
      throw StateError('Invalid answer sequence');
    }
    if (!b.containsKey(key)) await b.put(key, jsonEncode(run));
    await b.put('$key.answer.${answer['sequence']}', jsonEncode(answer));
    await b.flush();
    _apply(run, answer);
    await b.put(key, jsonEncode(run));
    await b.flush();
    return run;
  });
  Future<void> closeRun(String id) => locked(() async {
    final b = await box, key = '$scope.run.$id';
    if (!b.containsKey(key)) return;
    final run = await _restore(b, key);
    run['closed'] = true;
    await b.put(key, jsonEncode(run));
    await b.flush();
  });
  Future<void> upload() {
    if (_syncing != null) return _syncing!;
    if (userId == null) {
      return Future.error(
        const SocialException('برای بارگذاری نتایج وارد حساب شوید.', 401),
      );
    }
    _syncing = _upload().whenComplete(() => _syncing = null);
    return _syncing!;
  }

  Future<void> _upload() async {
    for (final initial in await runs()) {
      final id = initial['id'] as String;
      while (!disposed) {
        final batch = await locked(() async {
          final b = await box,
              run = await _restore(b, '$scope.run.$id'),
              answers = <dynamic>[];
          for (
            var i = (run['ack'] as int) + 1;
            i <= (run['answerCount'] as int) && answers.length < 100;
            i++
          ) {
            answers.add(jsonDecode(b.get('$scope.run.$id.answer.$i')!));
          }
          return <String, dynamic>{...run, 'answers': answers};
        });
        final ack = batch['ack'] as int,
            count = batch['answerCount'] as int,
            answers = batch['answers'] as List;
        if (count == 0 ||
            ack == count &&
                (batch['closed'] != true || batch['closedAck'] == true)) {
          break;
        }
        final exam = Map<String, dynamic>.from(batch['exam'] as Map),
            closed = batch['closed'] == true && ack + answers.length == count;
        final response = await request('results', {
          'runId': id,
          'examId': exam['id'],
          'version': exam['version'],
          'stage': batch['stage'],
          'permitExpiresAt': exam['permitExpiresAt'],
          'downloadPermit': exam['downloadPermit'],
          'answers': answers,
          'closed': closed,
        });
        if (response['acceptedThrough'] != ack + answers.length) {
          throw const SocialException('تأیید ثبت پاسخ معتبر نیست.');
        }
        await locked(() async {
          final b = await box,
              key = '$scope.run.$id',
              run = await _restore(b, key);
          run['ack'] = ack + answers.length;
          if (closed) run['closedAck'] = true;
          await b.put(key, jsonEncode(run));
          await b.flush();
        });
        if (closed) break;
      }
    }
  }

  String newRunId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  void dispose() {
    disposed = true;
    client.close();
  }
}
