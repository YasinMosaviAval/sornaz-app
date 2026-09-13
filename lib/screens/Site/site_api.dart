import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Social/social_api.dart';

class SiteApi {
  SiteApi({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;
  static Uri get origin => Uri.parse(SocialApi.base).resolve('/');
  static Uri url(String path, [Map<String, String>? query]) => origin
      .resolve(path)
      .replace(queryParameters: {'lang': SocialApi.locale, ...?query});
  Future<Json> get(String path, [Map<String, String>? query]) async {
    final response = await client
        .get(
          Uri.parse('${SocialApi.base}$path').replace(queryParameters: query),
          headers: {
            'Accept': 'application/json',
            'Accept-Language': SocialApi.locale,
          },
        )
        .timeout(const Duration(seconds: 25));
    return decode(response);
  }

  static Json decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SocialException(
        'دریافت اطلاعات ناموفق بود. دوباره تلاش کنید.',
        response.statusCode,
      );
    }
    final envelope = optionalObject(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );
    final data = optionalObject(envelope['data']);
    if (data['success'] == false) {
      throw const SocialException('دریافت اطلاعات ناموفق بود.');
    }
    return data;
  }

  void dispose() => client.close();
}
