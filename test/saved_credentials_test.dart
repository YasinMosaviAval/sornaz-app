import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sornaz/screens/Authentication/services/saved_credentials.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'remembered credentials persist, exclude signed-in accounts and update by user id',
    () async {
      final store = SavedCredentials();
      await store.update(
        const SavedCredential(1, 'first', 'password1'),
        remember: true,
      );
      await store.update(
        const SavedCredential(2, 'second', 'password2'),
        remember: true,
      );
      final restored = SavedCredentials();
      expect((await restored.available({1})).single.identifier, 'second');
      await restored.update(
        const SavedCredential(2, 'new-email', 'new-password'),
        remember: true,
      );
      expect((await restored.available({1})).single.password, 'new-password');
      expect((await restored.available({})).length, 2);
      await restored.update(
        const SavedCredential(2, 'new-email', 'new-password'),
        remember: false,
      );
      expect((await restored.available({})).single.userId, 1);
      expect(await restored.available({1}), isEmpty);
    },
  );

  test('profile avatar survives persisted session round trip', () {
    final user = AuthUser.fromJson({
      'id': 1,
      'username': 'user',
      'avatar': '/uploads/avatar.jpg',
    });
    expect(AuthUser.fromJson(user.toJson()).avatar, '/uploads/avatar.jpg');
  });
}
