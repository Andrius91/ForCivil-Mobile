import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart' show ApiException;

class ProjectService {
  ProjectService({http.Client? client, String baseUrl = _defaultBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://api.codepass.lat';

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<ProjectDetail> fetchProject({
    required String token,
    required int projectId,
  }) async {
    final response = await _client.get(
      _uri('/projects/$projectId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al obtener el proyecto',
        statusCode: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }
    return ProjectDetail.fromJson(body['data'] as Map<String, dynamic>);
  }
}

class ProjectDetail {
  ProjectDetail({
    required this.id,
    this.mondayHourLimit,
    this.tuesdayHourLimit,
    this.wednesdayHourLimit,
    this.thursdayHourLimit,
    this.fridayHourLimit,
    this.saturdayHourLimit,
    this.sundayHourLimit,
  });

  final int id;
  final double? mondayHourLimit;
  final double? tuesdayHourLimit;
  final double? wednesdayHourLimit;
  final double? thursdayHourLimit;
  final double? fridayHourLimit;
  final double? saturdayHourLimit;
  final double? sundayHourLimit;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    double? _double(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
    return ProjectDetail(
      id: json['id'] as int,
      mondayHourLimit: _double(json['mondayHourLimit']),
      tuesdayHourLimit: _double(json['tuesdayHourLimit']),
      wednesdayHourLimit: _double(json['wednesdayHourLimit']),
      thursdayHourLimit: _double(json['thursdayHourLimit']),
      fridayHourLimit: _double(json['fridayHourLimit']),
      saturdayHourLimit: _double(json['saturdayHourLimit']),
      sundayHourLimit: _double(json['sundayHourLimit']),
    );
  }

  double? limitForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return mondayHourLimit;
      case DateTime.tuesday:
        return tuesdayHourLimit;
      case DateTime.wednesday:
        return wednesdayHourLimit;
      case DateTime.thursday:
        return thursdayHourLimit;
      case DateTime.friday:
        return fridayHourLimit;
      case DateTime.saturday:
        return saturdayHourLimit;
      case DateTime.sunday:
        return sundayHourLimit;
      default:
        return null;
    }
  }
}
