import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sornaz/screens/Social/social_api.dart';

/// Offline-first storage for the bundled notation editor.
/// Editing never requires the network; uploading is an explicit operation.
class NotationApi {
  NotationApi(this.token, {http.Client? client, this.userId = 0})
    : _client = client ?? http.Client();
  final String token;
  final int userId;
  final Map<int, Map<String, dynamic>> _fetched = {};
  final http.Client _client;
  String get _storageKey => 'notation_local_v3_$userId';
  void close() => _client.close();

  Future<Map<String, dynamic>> _local() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final current = prefs.getString(_storageKey);
      if (current != null) {
        return Map<String, dynamic>.from(jsonDecode(current) as Map);
      }
      final legacy = prefs.getString('notation_local_v2_$userId');
      if (legacy == null) return {};
      final migrated = Map<String, dynamic>.from(jsonDecode(legacy) as Map);
      await prefs.setString(_storageKey, jsonEncode(migrated));
      return migrated;
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> entries) async =>
      (await SharedPreferences.getInstance()).setString(
        _storageKey,
        jsonEncode(entries),
      );

  Future<void> remember(Map<String, dynamic> sheet) async {
    final entries = await _local();
    entries['${sheet['id']}'] = {
      ...sheet,
      'local': true,
      'uploaded': true,
      'remote_id': sheet['id'],
      'remote_version': sheet['version'],
    };
    await _write(entries);
  }

  Future<void> markDownloaded(int id) async {
    final sheet = _fetched[id];
    if (sheet != null) await remember(sheet);
  }

  int _newLocalId(Map<String, dynamic> entries) {
    var id = -DateTime.now().microsecondsSinceEpoch;
    while (entries.containsKey('$id')) {
      id--;
    }
    return id;
  }

  Map<String, dynamic> _summary(Map<String, dynamic> sheet) {
    final metadata = Map<String, dynamic>.from(sheet['metadata'] as Map? ?? {});
    return {
      ...sheet,
      'title': metadata['title'] ?? sheet['title'] ?? '',
      'author': sheet['author'] ?? '',
      'metadata': metadata,
      'editable': true,
      'local': true,
    };
  }

  Future<dynamic> request(String action, Map<String, dynamic> message) async {
    if (action == 'instruments') return _instruments();
    if (action == 'list') {
      final local = await _local();
      final mode = message['mode'];
      final items =
          local.values
              .whereType<Map>()
              .map((item) => _summary(Map<String, dynamic>.from(item)))
              .where(
                (item) =>
                    ['all', 'mine'].contains(mode) ||
                    mode == 'local' && item['uploaded'] != true ||
                    mode == 'uploaded' && item['uploaded'] == true,
              )
              .toList()
            ..sort(
              (a, b) => '${b['updated_at'] ?? ''}'.compareTo(
                '${a['updated_at'] ?? ''}',
              ),
            );
      return {
        'items': message['page'] == 1 ? items : <dynamic>[],
        'has_more': false,
      };
    }
    if (action == 'get') {
      final id = message['sheetId'];
      final local = await _local();
      if (local.containsKey('$id')) {
        return _summary(Map<String, dynamic>.from(local['$id'] as Map));
      }
      final value = await _requestRemote('get', message);
      if (value is Map) {
        final sheet = Map<String, dynamic>.from(value);
        _fetched[sheet['id'] as int] = sheet;
        await remember(sheet);
      }
      return value;
    }
    if (action == 'save') return _saveLocal(message);
    if (action == 'delete') {
      final local = await _local();
      local.remove('${message['sheetId']}');
      await _write(local);
      return true;
    }
    if (action == 'bookmark') {
      final local = await _local();
      final key = '${message['sheetId']}';
      final sheet = Map<String, dynamic>.from(local[key] as Map? ?? {});
      if (sheet.isEmpty) throw const FormatException('Invalid sheet.');
      sheet['saved'] = message['payload']?['active'] == true;
      local[key] = sheet;
      await _write(local);
      return sheet;
    }
    if (action == 'upload') return _upload(message);
    throw const FormatException('Invalid operation.');
  }

  Future<Map<String, dynamic>> _saveLocal(Map<String, dynamic> message) async {
    if (message['payload'] is! Map) {
      throw const FormatException('Invalid sheet.');
    }
    if (utf8.encode(jsonEncode(message['payload'])).length > 300000) {
      throw const FormatException('Sheet is too large.');
    }
    final entries = await _local();
    final requested = message['sheetId'];
    final id = requested is int && requested != 0
        ? requested
        : _newLocalId(entries);
    final previous = Map<String, dynamic>.from(entries['$id'] as Map? ?? {});
    final payload = Map<String, dynamic>.from(message['payload'] as Map);
    final sheet = <String, dynamic>{
      ...previous,
      ...payload,
      'id': id,
      'version': (previous['version'] as num? ?? 0).toInt() + 1,
      'editable': true,
      'local': true,
      'uploaded': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    entries['$id'] = sheet;
    await _write(entries);
    return _summary(sheet);
  }

  Future<Map<String, dynamic>> _upload(Map<String, dynamic> message) async {
    if (token.isEmpty) throw const SocialException('Sign in to continue.', 401);
    final local = await _local();
    final key = '${message['sheetId']}';
    final sheet = Map<String, dynamic>.from(local[key] as Map? ?? {});
    if (sheet.isEmpty) throw const FormatException('Invalid sheet.');
    final localId = (sheet['id'] as num?)?.toInt() ?? 0;
    final remoteId =
        (sheet['remote_id'] as num?)?.toInt() ?? (localId > 0 ? localId : 0);
    final uploaded = await _requestRemote('save', {
      'sheetId': remoteId,
      'payload': {
        'metadata': sheet['metadata'],
        'score': sheet['score'],
        'visibility': sheet['visibility'] ?? 'private',
        if (remoteId != 0) 'version': sheet['remote_version'] ?? 0,
      },
    });
    if (uploaded is! Map) {
      throw const SocialException('Notation service unavailable.');
    }
    final remote = Map<String, dynamic>.from(uploaded);
    sheet.addAll({
      'uploaded': true,
      'remote_id': remote['id'],
      'remote_version': remote['version'],
      'uploaded_at': DateTime.now().toUtc().toIso8601String(),
    });
    local[key] = sheet;
    await _write(local);
    return _summary(sheet);
  }

  Future<dynamic> _instruments() async {
    final prefs = await SharedPreferences.getInstance();
    const bundled = [
      {'id': 'piano', 'fa': 'پیانو', 'en': 'Piano'},
      {'id': 'guitar', 'fa': 'گیتار', 'en': 'Guitar'},
      {'id': 'violin', 'fa': 'ویولن', 'en': 'Violin'},
      {'id': 'voice', 'fa': 'آواز', 'en': 'Voice'},
    ];
    final cached = prefs.getString('notation_instruments_v1');
    unawaited(_refreshInstruments(prefs));
    return cached == null ? bundled : jsonDecode(cached);
  }

  Future<void> _refreshInstruments(SharedPreferences prefs) async {
    try {
      final value = await _requestRemote('instruments', {});
      if (value is List) {
        await prefs.setString('notation_instruments_v1', jsonEncode(value));
      }
    } catch (_) {}
  }

  Future<dynamic> _requestRemote(
    String action,
    Map<String, dynamic> message,
  ) async {
    final id = message['sheetId'];
    if (!['get', 'save', 'instruments'].contains(action)) {
      throw const FormatException('Invalid operation.');
    }
    if (action != 'instruments' && (id is! int || id < 0)) {
      throw const FormatException('Invalid sheet.');
    }
    var suffix = action == 'instruments' ? '/instruments' : '';
    if (action == 'get' || (action == 'save' && id != 0)) suffix = '/$id';
    final url = Uri.parse(
      '${SocialApi.base.replaceFirst(RegExp(r'/$'), '')}/music-sheets$suffix',
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (action == 'save' && token.isEmpty) {
      throw const SocialException('Sign in to continue.', 401);
    }
    final response =
        await (action == 'save'
                ? _client.post(
                    url,
                    headers: headers,
                    body: jsonEncode(message['payload']),
                  )
                : _client.get(url, headers: headers))
            .timeout(const Duration(seconds: 25));
    Map<String, dynamic> result;
    try {
      result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (result['status'] != null && result['data'] is Map) {
        result = Map<String, dynamic>.from(result['data']);
      }
    } catch (_) {
      throw const SocialException('Notation service unavailable.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw SocialException(
        result['message']?.toString() ?? 'Notation service unavailable.',
        response.statusCode,
      );
    }
    return result['data'];
  }
}
