import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'auth_service.dart' show ApiException;

class AttendanceService {
  AttendanceService({http.Client? client, String baseUrl = _defaultBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://api.forcivil.com';

  final http.Client _client;
  final String _baseUrl;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<AttendanceRecord>> fetchCrewAttendance({
    required String token,
    required int projectId,
    required int crewId,
    required DateTime date,
  }) async {
    final dateString = _dateFormat.format(date);
    final response = await _client.get(
      _uri('/attendance/crew/$crewId').replace(queryParameters: {
        'date': dateString,
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'X-Project-Id': projectId.toString(),
      },
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al obtener la asistencia',
        statusCode: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }
    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => AttendanceRecord.fromJson(json))
        .toList();
  }

  Future<AttendanceRecord> registerCheckIn({
    required String token,
    required int projectId,
    required String dni,
    required DateTime timestamp,
  }) async {
    final dateString = _dateFormat.format(timestamp);
    final timeString = _timeFormat.format(timestamp);
    return _postAttendance(
      token: token,
      projectId: projectId,
      path: '/attendance/check-in',
      payload: {
        'dni': dni,
        'date': dateString,
        'checkInTime': timeString,
      },
    );
  }

  Future<AttendanceRecord> registerCheckOut({
    required String token,
    required int projectId,
    required String dni,
    required DateTime timestamp,
  }) async {
    final dateString = _dateFormat.format(timestamp);
    final timeString = _timeFormat.format(timestamp);
    return _postAttendance(
      token: token,
      projectId: projectId,
      path: '/attendance/check-out',
      payload: {
        'dni': dni,
        'date': dateString,
        'checkOutTime': timeString,
      },
    );
  }

  Future<AttendanceRecord> _postAttendance({
    required String token,
    required int projectId,
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Project-Id': projectId.toString(),
      },
      body: jsonEncode(payload),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al registrar asistencia',
        statusCode: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respuesta inválida');
    }
    return AttendanceRecord.fromJson(data);
  }
}

class AttendanceRecord {
  AttendanceRecord({
    required this.personId,
    required this.projectId,
    required this.crewId,
    required this.dni,
    required this.fullName,
    required this.present,
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.hoursNormal,
    required this.hoursExtra,
  });

  final int? personId;
  final int? projectId;
  final int? crewId;
  final String dni;
  final String fullName;
  final bool present;
  final DateTime? date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? hoursNormal;
  final double? hoursExtra;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final dateString = json['date']?.toString();
    return AttendanceRecord(
      personId: json['personId'] as int?,
      projectId: json['projectId'] as int?,
      crewId: json['crewId'] as int?,
      dni: json['dni']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      present: json['present'] as bool? ?? true,
      date: DateTime.tryParse(dateString ?? ''),
      checkInTime: _parseDateTime(dateString, json['checkInTime']?.toString()),
      checkOutTime:
          _parseDateTime(dateString, json['checkOutTime']?.toString()),
      hoursNormal: _toDouble(json['hoursNormal']),
      hoursExtra: _toDouble(json['hoursExtra']),
    );
  }

  static DateTime? _parseDateTime(String? date, String? time) {
    if (date == null || time == null || date.isEmpty || time.isEmpty) {
      return null;
    }
    final normalized = time.length == 5 ? '${time}:00' : time;
    final iso = '${date}T$normalized';
    return DateTime.tryParse(iso);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
