import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedCredential {
  const SavedCredential(this.userId, this.identifier, this.password, {this.avatar});
  final int userId;
  final String identifier;
  final String password;
  final String? avatar;
}

class SavedCredentials {
  SavedCredentials({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'remembered_credentials_v1';
  static final site = Uri.parse(
    const String.fromEnvironment(
      'Sornaz_API_BASE_URL',
      defaultValue: 'https://sornaz.com/api/sornaz/v1',
    ),
  ).host;

  Future<List<SavedCredential>> available(Set<int> signedIn) async {
    final raw = await _storage.read(key: '$_key:$site');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map(
          (e) => SavedCredential(
            e['id'] as int,
            e['identifier'] as String,
            e['password'] as String,
            avatar: e['avatar'] as String?,
          ),
        )
        .where((e) => !signedIn.contains(e.userId))
        .toList();
  }

  Future<void> updateAvatar(int userId,String? avatar)async{
    final entries=await available({});
    for(final entry in entries){if(entry.userId==userId){await update(SavedCredential(entry.userId,entry.identifier,entry.password,avatar:avatar),remember:true);break;}}
  }
  Future<void> update(SavedCredential entry, {required bool remember}) async {
    final entries = await available({});
    entries.removeWhere((e) => e.userId == entry.userId);
    if (remember) entries.add(entry);
    await _storage.write(
      key: '$_key:$site',
      value: jsonEncode(
        entries
            .map(
              (e) => {
                'id': e.userId,
                'identifier': e.identifier,
                'password': e.password,
                'avatar': e.avatar,
              },
            )
            .toList(),
      ),
    );
  }
}
