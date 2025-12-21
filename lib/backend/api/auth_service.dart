import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class LoginPayload {
  LoginPayload({required this.usernameOrEmail, required this.password});

  final String usernameOrEmail;
  final String password;

  Map<String, dynamic> toJson() => {
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      };
}

class LoginResponseData {
  LoginResponseData({
    required this.token,
    required this.expiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.userId,
    required this.companyId,
    required this.schema,
    required this.fullName,
  });

  final String token;
  final DateTime expiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final int userId;
  final int companyId;
  final String schema;
  final String fullName;

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      refreshToken: json['refreshToken'] as String,
      refreshExpiresAt: DateTime.parse(json['refreshExpiresAt'] as String),
      userId: json['userId'] as int,
      companyId: json['companyId'] as int,
      schema: json['schema'] as String,
      fullName: json['fullName'] as String,
    );
  }
}

class ProjectRole {
  ProjectRole({
    required this.membershipId,
    required this.projectId,
    required this.projectName,
    required this.roleId,
    required this.roleName,
    required this.active,
  });

  final int membershipId;
  final int projectId;
  final String projectName;
  final int roleId;
  final String roleName;
  final bool active;

  factory ProjectRole.fromJson(Map<String, dynamic> json) {
    return ProjectRole(
      membershipId: json['membershipId'] as int,
      projectId: json['projectId'] as int,
      projectName: json['projectName'] as String,
      roleId: json['roleId'] as int,
      roleName: json['roleName'] as String,
      active: json['active'] as bool,
    );
  }
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.username,
    required this.email,
    required this.fullName,
    required this.active,
    required this.projectRoles,
  });

  final int id;
  final int companyId;
  final String companyName;
  final String username;
  final String email;
  final String fullName;
  final bool active;
  final List<ProjectRole> projectRoles;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roles = (json['projectRoles'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ProjectRole.fromJson)
        .toList();
    return UserProfile(
      id: json['id'] as int,
      companyId: json['companyId'] as int,
      companyName: json['companyName'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      active: json['active'] as bool,
      projectRoles: roles,
    );
  }
}

class AuthService {
  AuthService({http.Client? client, String baseUrl = _defaultBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://api.codepass.lat';

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<LoginResponseData> login(LoginPayload payload) async {
    final response = await _client.post(
      _uri('/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload.toJson()),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al iniciar sesión',
        statusCode: response.statusCode,
      );
    }

    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }

    return LoginResponseData.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<LoginResponseData> refreshToken(String refreshToken) async {
    final response = await _client.post(
      _uri('/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'No se pudo refrescar la sesión',
        statusCode: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }
    return LoginResponseData.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> fetchCurrentUser(String token) async {
    final response = await _client.get(
      _uri('/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al obtener el perfil',
        statusCode: response.statusCode,
      );
    }

    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }

    return UserProfile.fromJson(body['data'] as Map<String, dynamic>);
  }
}
