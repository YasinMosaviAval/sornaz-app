import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sornaz/screens/Social/social_api.dart';

/// Only the bundled editor can request these operations. Credentials stay native.
class NotationApi {
  NotationApi(this.token, {http.Client? client, this.userId = 0})
    : _client = client ?? http.Client();
  final String token;
  final int userId;
  final Map<int, Map<String, dynamic>> _fetched = {};
  final http.Client _client;
  void close() => _client.close();

  Future<Map<String, dynamic>> _local() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return Map<String, dynamic>.from(
        jsonDecode(prefs.getString('notation_local_v2_$userId') ?? '{}'),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> remember(Map<String, dynamic> sheet) async {
    final entries = await _local();
    entries[sheet['id'].toString()] = {...sheet, 'local': true};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notation_local_v2_$userId', jsonEncode(entries));
  }

  Future<void> markDownloaded(int id) async {
    final sheet = _fetched[id];
    if (sheet != null) await remember(sheet);
  }

  Future<dynamic> request(String action, Map<String, dynamic> message) async {
    try {
      final value = await _requestRemote(action, message);
      if (action == 'instruments' && value is List) {
        await (await SharedPreferences.getInstance()).setString(
          'notation_instruments_v1',
          jsonEncode(value),
        );
      }
      if ((action == 'get' || action == 'save') && value is Map) {
        final sheet = Map<String, dynamic>.from(value);
        _fetched[sheet['id'] as int] = sheet;
        if (action == 'save' ||
            (await _local()).containsKey(sheet['id'].toString()))
          await remember(sheet);
      }
      if (action == 'list' && value is Map) {
        final local = await _local();
        for (final item in value['items'] as List) {
          final cached = local[item['id'].toString()];
          item['local'] =
              cached != null && cached['version'] == item['version'];
        }
      }
      if (action == 'delete') {
        final local = await _local();
        local.remove(message['sheetId'].toString());
        await (await SharedPreferences.getInstance()).setString(
          'notation_local_v2_$userId',
          jsonEncode(local),
        );
      }
      return value;
    } on SocialException {
      if (action == 'instruments') {
        final cached = (await SharedPreferences.getInstance()).getString(
          'notation_instruments_v1',
        );
        if (cached != null) return jsonDecode(cached);
      }
      rethrow;
    } catch (error) {
      if (error is FormatException) rethrow;
      if (action == 'instruments') {
        final cached = (await SharedPreferences.getInstance()).getString(
          'notation_instruments_v1',
        );
        if (cached != null) return jsonDecode(cached);
      }
      final local = await _local();
      if (action == 'get' && local.containsKey(message['sheetId'].toString()))
        return local[message['sheetId'].toString()];
      if (action == 'list' && local.isNotEmpty) {
        final items = local.values
            .where(
              (s) => message['mode'] == 'mine'
                  ? s['editable'] == true
                  : message['mode'] == 'saved'
                  ? s['saved'] == true
                  : true,
            )
            .toList();
        return {'items': message['page'] == 1 ? items : [], 'has_more': false};
      }
      rethrow;
    }
  }

  Future<dynamic> _requestRemote(
    String action,
    Map<String, dynamic> message,
  ) async {
    final id = message['sheetId'];
    if (![
      'list',
      'get',
      'save',
      'delete',
      'bookmark',
      'instruments',
    ].contains(action)) {
      throw const FormatException('Invalid operation.');
    }
    if (!['list', 'instruments'].contains(action) &&
        (id is! int || id < 0 || (action != 'save' && id == 0))) {
      throw const FormatException('Invalid sheet.');
    }
    String suffix = action == 'instruments' ? '/instruments' : '';
    if (action == 'list') {
      final mode = message['mode'];
      final page = message['page'];
      if (!['all', 'mine', 'saved'].contains(mode) ||
          page is! int ||
          page < 1 ||
          page > 10000) {
        throw const FormatException('Invalid list.');
      }
      suffix = '?mode=$mode&page=$page';
    } else if (action == 'get' || (action == 'save' && id != 0)) {
      suffix = '/$id';
    } else if (action == 'delete' || action == 'bookmark') {
      suffix = '/$id/$action';
    }
    final url = Uri.parse(
      '${SocialApi.base.replaceFirst(RegExp(r'/$'), '')}/music-sheets$suffix',
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final write = !['list', 'get', 'instruments'].contains(action);
    if (write && token.isEmpty) {
      throw const SocialException('Sign in to continue.', 401);
    }
    final payload = write ? jsonEncode(message['payload']) : null;
    if (write &&
        (message['payload'] is! Map || utf8.encode(payload!).length > 300000)) {
      throw const FormatException('Sheet is too large.');
    }
    final response =
        await (write
                ? _client.post(url, headers: headers, body: payload)
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
