import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart' show ApiException;

class ProjectService {
  ProjectService({http.Client? client, String baseUrl = _defaultBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://api.forcivil.com';

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
  ProjectDetail({required this.id, required Map<int, double?> hourLimits})
      : _hourLimits = hourLimits;

  final int id;
  final Map<int, double?> _hourLimits;

  static const Map<String, int> _weekdayKeys = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String && value.isNotEmpty) {
        return double.tryParse(value);
      }
      return null;
    }

    final limits = <int, double?>{};
    void addLimit(int weekday, dynamic value) {
      final parsed = parseDouble(value);
      if (parsed != null) {
        limits[weekday] = parsed;
      }
    }

    final hourLimits = json['hourLimits'];
    if (hourLimits is Map) {
      hourLimits.forEach((key, value) {
        final weekday = _weekdayKeys[key.toString().toLowerCase()];
        if (weekday != null) {
          addLimit(weekday, value);
        }
      });
    } else {
      addLimit(DateTime.monday, json['mondayHourLimit']);
      addLimit(DateTime.tuesday, json['tuesdayHourLimit']);
      addLimit(DateTime.wednesday, json['wednesdayHourLimit']);
      addLimit(DateTime.thursday, json['thursdayHourLimit']);
      addLimit(DateTime.friday, json['fridayHourLimit']);
      addLimit(DateTime.saturday, json['saturdayHourLimit']);
      addLimit(DateTime.sunday, json['sundayHourLimit']);
    }

    return ProjectDetail(
      id: json['id'] as int,
      hourLimits: limits,
    );
  }

  double? limitForDate(DateTime date) => _hourLimits[date.weekday];

  double? limitForWeekday(int weekday) => _hourLimits[weekday];
}
