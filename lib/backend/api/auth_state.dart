import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService();

  static const _tokenKey = 'auth_token';

  final AuthService _service;

  String? _token;
  UserProfile? _profile;

  String? get token => _token;
  UserProfile? get profile => _profile;
  bool get isAuthenticated => _token != null && _profile != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null) {
      return;
    }

    _token = savedToken;
    try {
      _profile = await _service.fetchCurrentUser(savedToken);
    } catch (_) {
      await logout();
      return;
    }
    notifyListeners();
  }

  Future<void> login(String usernameOrEmail, String password) async {
    final loginData = await _service
        .login(LoginPayload(usernameOrEmail: usernameOrEmail, password: password));

    _token = loginData.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, loginData.token);

    _profile = await _service.fetchCurrentUser(loginData.token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }
}
