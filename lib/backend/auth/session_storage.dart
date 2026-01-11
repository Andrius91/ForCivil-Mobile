import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String token;
  final String refreshToken;
  final DateTime expiresAt;

  Map<String, String> toMap() => {
        _tokenKey: token,
        _refreshKey: refreshToken,
        _expiryKey: expiresAt.toIso8601String(),
      };

  static AuthSession? fromMap(Map<String, String?> values) {
    final token = values[_tokenKey];
    final refresh = values[_refreshKey];
    final expiryString = values[_expiryKey];
    if (token == null || refresh == null || expiryString == null) {
      return null;
    }
    final expiry = DateTime.tryParse(expiryString);
    if (expiry == null) {
      return null;
    }
    return AuthSession(token: token, refreshToken: refresh, expiresAt: expiry);
  }

  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  static const _expiryKey = 'auth_token_expiry';
}

abstract class SessionStorage {
  Future<void> save(AuthSession session);
  Future<AuthSession?> read();
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(AuthSession session) async {
    final data = session.toMap();
    for (final entry in data.entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }

  @override
  Future<AuthSession?> read() async {
    final token = await _storage.read(key: AuthSession._tokenKey);
    final refresh = await _storage.read(key: AuthSession._refreshKey);
    final expiry = await _storage.read(key: AuthSession._expiryKey);
    return AuthSession.fromMap({
      AuthSession._tokenKey: token,
      AuthSession._refreshKey: refresh,
      AuthSession._expiryKey: expiry,
    });
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: AuthSession._tokenKey);
    await _storage.delete(key: AuthSession._refreshKey);
    await _storage.delete(key: AuthSession._expiryKey);
  }
}

class InMemorySessionStorage implements SessionStorage {
  AuthSession? _session;

  @override
  Future<void> save(AuthSession session) async {
    _session = session;
  }

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> clear() async {
    _session = null;
  }
}
