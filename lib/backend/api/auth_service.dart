import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

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
    required this.projectId,
    required this.projectName,
    this.membershipId,
    this.projectCode,
    this.roleId,
    this.roleName,
    this.roleDescription,
    this.frontId,
    this.frontName,
    bool? active,
  }) : active = active ?? true;

  final int? membershipId;
  final int projectId;
  final String projectName;
  final String? projectCode;
  final int? roleId;
  final String? roleName;
  final String? roleDescription;
  final bool active;
  final int? frontId;
  final String? frontName;

  String get displayRole =>
      (roleName != null && roleName!.isNotEmpty) ? roleName! : 'Miembro';
  bool get isActive => active;

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final stringValue = value.toString();
    return stringValue.trim().isEmpty ? null : stringValue;
  }

  factory ProjectRole.fromJson(Map<String, dynamic> json) {
    int? resolveProjectId() {
      return _asInt(json['projectId']) ??
          _asInt(json['id']) ??
          _asInt(json['project']?['id']);
    }

    String resolveProjectName() {
      return _asString(json['projectName']) ??
          _asString(json['name']) ??
          _asString(json['project']?['name']) ??
          'Proyecto';
    }

    final resolvedProjectId = resolveProjectId();
    if (resolvedProjectId == null) {
      throw ApiException('Proyecto inválido en la sesión del usuario');
    }

    return ProjectRole(
      membershipId: _asInt(json['membershipId'] ?? json['assignmentId']),
      projectId: resolvedProjectId,
      projectName: resolveProjectName(),
      projectCode: _asString(json['projectCode'] ?? json['code']),
      roleId: _asInt(json['roleId']),
      roleName: _asString(json['roleName'] ?? json['role']),
      roleDescription: _asString(json['roleDescription']),
      frontId: _asInt(json['frontId']),
      frontName: _asString(json['frontName']),
      active: _asBool(json['active']) ?? true,
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
    List<ProjectRole> parseRoles() {
      final rawRoles = json['projectRoles'];
      if (rawRoles is List) {
        return rawRoles
            .whereType<Map<String, dynamic>>()
            .map(ProjectRole.fromJson)
            .toList();
      }
      final rawProjects = json['projects'];
      if (rawProjects is List) {
        return rawProjects
            .whereType<Map<String, dynamic>>()
            .map(ProjectRole.fromJson)
            .toList();
      }
      return const [];
    }

    final roles = parseRoles();
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
  AuthService({http.Client? client, ApiConfig? config})
      : _client = client ?? http.Client(),
        _config = config ?? ApiConfig.instance;

  final http.Client _client;
  final ApiConfig _config;

  Uri _uri(String path) => _config.uri(path);

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
