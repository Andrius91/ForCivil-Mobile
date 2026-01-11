import 'dart:async';

import 'package:flutter/material.dart';
import '../auth/session_storage.dart';
import 'auth_service.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service, SessionStorage? storage})
      : _service = service ?? AuthService(),
        _storage = storage ?? SecureSessionStorage();

  final AuthService _service;
  final SessionStorage _storage;

  String? _token;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  UserProfile? _profile;
  ProjectRole? _selectedProject;
  Completer<void>? _refreshCompleter;

  String? get token => _token;
  UserProfile? get profile => _profile;
  ProjectRole? get selectedProject => _selectedProject;
  bool get isAuthenticated => _token != null && _profile != null;

  Future<void> restoreSession() async {
    final storedSession = await _storage.read();
    if (storedSession == null) {
      return;
    }

    _token = storedSession.token;
    _refreshToken = storedSession.refreshToken;
    _tokenExpiry = storedSession.expiresAt;
    try {
      await _refreshTokenIfNeeded();
      final token = _token;
      if (token == null) {
        await logout();
        return;
      }
      _profile = await _service.fetchCurrentUser(token);
    } catch (_) {
      await logout();
      return;
    }
    _selectedProject = null;
    notifyListeners();
  }

  Future<void> login(String usernameOrEmail, String password) async {
    final loginData = await _service.login(
        LoginPayload(usernameOrEmail: usernameOrEmail, password: password));

    await _persistSession(loginData);

    _profile = await _service.fetchCurrentUser(loginData.token);
    _selectedProject = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _profile = null;
    _selectedProject = null;
    await _storage.clear();
    notifyListeners();
  }

  Future<String?> ensureValidToken() async {
    await _refreshTokenIfNeeded();
    return _token;
  }

  void selectProject(ProjectRole role) {
    _selectedProject = role;
    notifyListeners();
  }

  void clearSelectedProject() {
    _selectedProject = null;
    notifyListeners();
  }

  Future<void> _persistSession(LoginResponseData data) async {
    _token = data.token;
    _refreshToken = data.refreshToken;
    _tokenExpiry = data.expiresAt;
    await _storage.save(
      AuthSession(
        token: data.token,
        refreshToken: data.refreshToken,
        expiresAt: data.expiresAt,
      ),
    );
  }

  Future<void> _refreshTokenIfNeeded() async {
    final refresh = _refreshToken;
    if (refresh == null) {
      return;
    }
    final threshold = DateTime.now().add(const Duration(minutes: 1));
    if (_token != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(threshold)) {
      return;
    }
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<void>();
    try {
      final newData = await _service.refreshToken(refresh);
      await _persistSession(newData);
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}
