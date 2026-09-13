import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Authentication/providers/auth_session.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';
import 'package:sornaz/components/account_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sornaz/screens/Authentication/services/saved_credentials.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'avatar is retained with a remembered password and refreshed without losing it',
    () async {
      final store = SavedCredentials();
      await store.update(
        const SavedCredential(7, 'user', 'secret', avatar: '/old.png'),
        remember: true,
      );
      await store.updateAvatar(7, '/new.png');
      final value = (await SavedCredentials().available({})).single;
      expect(value.avatar, '/new.png');
      expect(value.password, 'secret');
      expect(
        AccountAvatar.url('uploads/avatar.png'),
        endsWith('/uploads/avatar.png'),
      );
      expect(AccountAvatar.url('https://untrusted.example/avatar.png'), isNull);
    },
  );
  test('logout of another account preserves the active account', () async {
    SharedPreferences.setMockInitialValues({});
    final session = AuthSession();
    await session.save(
      const AuthResult(
        token: 'one',
        user: AuthUser(id: 1, username: 'one', fullName: 'One'),
      ),
    );
    await session.save(
      const AuthResult(
        token: 'two',
        user: AuthUser(id: 2, username: 'two', fullName: 'Two'),
      ),
    );
    await session.clear(accountId: 1);
    expect(session.user!.id, 2);
    expect(session.token, 'two');
    expect(session.accounts, hasLength(1));
    await session.clear(accountId: 2);
    expect(session.user, isNull);
    session.dispose();
  });
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
