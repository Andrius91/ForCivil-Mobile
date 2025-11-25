import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart' show ApiException;

class CrewService {
  CrewService({http.Client? client, String baseUrl = _defaultBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://api.codepass.lat';

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((key, value) => MapEntry(key, value.toString())),
    });
  }

  Future<List<Crew>> fetchCrews({
    required int userId,
    required String token,
  }) async {
    final response = await _client.get(
      _uri('/crews/by-user', {'userId': userId}),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al obtener cuadrillas',
        statusCode: response.statusCode,
      );
    }

    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }

    final List<dynamic> data = body['data'] as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Crew.fromJson)
        .toList();
  }
}

class Crew {
  Crew({
    required this.id,
    required this.projectId,
    required this.name,
    required this.foremanUserId,
    required this.foremanName,
    required this.active,
    required this.members,
    required this.partidas,
  });

  final int id;
  final int projectId;
  final String name;
  final int foremanUserId;
  final String foremanName;
  final bool active;
  final List<CrewMember> members;
  final List<CrewPartida> partidas;

  factory Crew.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? const [];
    final partidasJson = json['partidas'] as List<dynamic>? ?? const [];
    return Crew(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      name: json['name'] as String,
      foremanUserId: json['foremanUserId'] as int,
      foremanName: json['foremanName'] as String,
      active: json['active'] as bool,
      members: membersJson
          .whereType<Map<String, dynamic>>()
          .map(CrewMember.fromJson)
          .toList(),
      partidas: partidasJson
          .whereType<Map<String, dynamic>>()
          .map(CrewPartida.fromJson)
          .toList(),
    );
  }
}

class CrewMember {
  CrewMember({
    required this.id,
    required this.name,
    required this.lastName,
    required this.category,
    required this.specialty,
    required this.photoUrl,
  });

  final int id;
  final String name;
  final String lastName;
  final String category;
  final String specialty;
  final String? photoUrl;

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: json['id'] as int,
      name: json['name'] as String,
      lastName: json['lastName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  String get fullName =>
      lastName.isNotEmpty ? '$name $lastName'.trim() : name.trim();
}

class CrewPartida {
  CrewPartida({
    required this.code,
    required this.name,
    required this.unit,
    required this.metric,
  });

  final String code;
  final String name;
  final String? unit;
  final num? metric;

  factory CrewPartida.fromJson(Map<String, dynamic> json) {
    return CrewPartida(
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String?,
      metric: json['metric'] as num?,
    );
  }
}
