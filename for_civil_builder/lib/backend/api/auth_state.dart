import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService();

  static const _tokenKey = 'auth_token';

  final AuthService _service;

  String? _token;
  UserProfile? _profile;
  ProjectRole? _selectedProject;

  String? get token => _token;
  UserProfile? get profile => _profile;
  ProjectRole? get selectedProject => _selectedProject;
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
    _selectedProject = null;
    notifyListeners();
  }

  Future<void> login(String usernameOrEmail, String password) async {
    final loginData = await _service.login(
        LoginPayload(usernameOrEmail: usernameOrEmail, password: password));

    _token = loginData.token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, loginData.token);

    _profile = await _service.fetchCurrentUser(loginData.token);
    _selectedProject = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _profile = null;
    _selectedProject = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  void selectProject(ProjectRole role) {
    _selectedProject = role;
    notifyListeners();
  }

  void clearSelectedProject() {
    _selectedProject = null;
    notifyListeners();
  }
}
