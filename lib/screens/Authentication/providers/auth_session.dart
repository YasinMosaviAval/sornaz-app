import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sornaz/screens/Authentication/models/auth_user.dart';
import 'package:sornaz/screens/Authentication/services/auth_api_service.dart';

class AuthSession extends ChangeNotifier {
  static const _accountsKey = 'auth_accounts_v1';
  final Map<int, AuthResult> _accounts = {};
  bool _changing = false;
  bool get isChanging => _changing;
  String? token;
  AuthUser? user;
  bool get isAuthenticated => token != null && user != null;
  List<AuthUser> get accounts =>
      List.unmodifiable(_accounts.values.map((a) => a.user));

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _accounts.clear();
    try {
      for (final entry
          in jsonDecode(prefs.getString(_accountsKey) ?? '[]') as List) {
        try {
          final u = AuthUser.fromJson(Map<String, dynamic>.from(entry['user']));
          final t = entry['token'] as String;
          if (t.isNotEmpty) _accounts[u.id] = AuthResult(token: t, user: u);
        } catch (_) {
          /* Ignore an invalid saved entry, preserving other accounts. */
        }
      }
    } catch (_) {
      /* Legacy session can still be restored. */
    }
    token = prefs.getString('auth_token');
    user = null;
    try {
      final raw = prefs.getString('auth_user');
      if (raw != null && token != null && token!.isNotEmpty) {
        user = AuthUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
        _accounts[user!.id] = AuthResult(token: token!, user: user!);
      }
    } catch (_) {
      user = null;
    }
    if (user == null) {
      final fallback = _accounts.values.firstOrNull;
      user = fallback?.user;
      token = fallback?.token;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsKey,
      jsonEncode(
        _accounts.values
            .map((a) => {'token': a.token, 'user': a.user.toJson()})
            .toList(),
      ),
    );
    if (isAuthenticated) {
      await prefs.setString('auth_token', token!);
      await prefs.setString('auth_user', jsonEncode(user!.toJson()));
    } else {
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    }
  }

  Future<void> save(AuthResult result) async {
    if (_changing) return;
    _changing = true;
    notifyListeners();
    try {
      _accounts[result.user.id] = result;
      token = result.token;
      user = result.user;
      await _persist();
    } finally {
      _changing = false;
      notifyListeners();
    }
  }

  Future<void> switchTo(int id) async {
    final account = _accounts[id];
    if (account == null) throw StateError('Account is not signed in');
    await save(account);
  }

  /// Removes only the active account; other signed-in sessions remain available.
  Future<void> clear() async {
    if (_changing) return;
    _changing = true;
    notifyListeners();
    try {
      _accounts.remove(user?.id);
      final next = _accounts.values.firstOrNull;
      token = next?.token;
      user = next?.user;
      await _persist();
    } finally {
      _changing = false;
      notifyListeners();
    }
  }
}
