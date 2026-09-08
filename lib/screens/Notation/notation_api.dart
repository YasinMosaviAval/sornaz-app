import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sornaz/screens/Social/social_api.dart';

/// Only the bundled editor can request these operations. Credentials stay native.
class NotationApi {
  NotationApi(this.token, {http.Client? client})
    : _client = client ?? http.Client();
  final String token;
  final http.Client _client;
  void close() => _client.close();

  Future<dynamic> request(String action, Map<String, dynamic> message) async {
    final id = message['sheetId'];
    if (!['list', 'get', 'save', 'delete', 'bookmark'].contains(action)) {
      throw const FormatException('Invalid operation.');
    }
    if (action != 'list' &&
        (id is! int || id < 0 || (action != 'save' && id == 0))) {
      throw const FormatException('Invalid sheet.');
    }
    String suffix = '';
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
    final write = !['list', 'get'].contains(action);
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
