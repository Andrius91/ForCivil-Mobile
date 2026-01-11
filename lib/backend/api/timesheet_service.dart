import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'auth_service.dart' show ApiException;
import 'api_config.dart';

class TimesheetService {
  TimesheetService({http.Client? client, ApiConfig? config})
      : _client = client ?? http.Client(),
        _config = config ?? ApiConfig.instance;

  final http.Client _client;
  final ApiConfig _config;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Uri _uri(String path) => _config.uri(path);

  Future<Timesheet> createTimesheet({
    required String token,
    required int projectId,
    required int crewId,
    required DateTime workDate,
    required List<TimesheetLineInput> lines,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      'crewId': crewId,
      'workDate': _dateFormat.format(workDate),
      'note': note,
      'lines': lines.map((e) => e.toJson()).toList(),
    }..removeWhere((key, value) => value == null);

    final response = await _client.post(
      _uri('/timesheets'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Project-Id': projectId.toString(),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al registrar el tareo',
        statusCode: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Formato de tareo inválido');
    }
    return Timesheet.fromJson(data);
  }
}

class TimesheetLineInput {
  TimesheetLineInput({
    required this.personId,
    required this.partidaId,
    required this.hoursRegular,
    required this.hoursOvertime,
  });

  final int personId;
  final int partidaId;
  final double hoursRegular;
  final double hoursOvertime;

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'partidaId': partidaId,
        'hoursRegular': hoursRegular,
        'hoursOvertime': hoursOvertime,
      };
}

class Timesheet {
  Timesheet({
    required this.id,
    required this.projectId,
    required this.crewId,
    required this.crewName,
    required this.workDate,
    required this.state,
    required this.lines,
  });

  final int id;
  final int projectId;
  final int crewId;
  final String crewName;
  final DateTime workDate;
  final String state;
  final List<TimesheetLine> lines;

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TimesheetLine.fromJson)
        .toList();
    return Timesheet(
      id: json['id'] as int,
      projectId: json['projectId'] as int,
      crewId: json['crewId'] as int,
      crewName: json['crewName']?.toString() ?? '',
      workDate: DateTime.tryParse(json['workDate']?.toString() ?? '') ??
          DateTime.now(),
      state: json['state']?.toString() ?? '',
      lines: lines,
    );
  }
}

class TimesheetLine {
  TimesheetLine({
    required this.id,
    required this.personId,
    required this.personName,
    required this.partidaId,
    required this.partidaName,
    required this.hoursRegular,
    required this.hoursOvertime,
  });

  final int id;
  final int personId;
  final String personName;
  final int partidaId;
  final String partidaName;
  final double hoursRegular;
  final double hoursOvertime;

  factory TimesheetLine.fromJson(Map<String, dynamic> json) {
    return TimesheetLine(
      id: json['id'] as int? ?? 0,
      personId: json['personId'] as int? ?? 0,
      personName: json['personName']?.toString() ?? '',
      partidaId: json['partidaId'] as int? ?? 0,
      partidaName: json['partidaName']?.toString() ?? '',
      hoursRegular: (json['hoursRegular'] as num?)?.toDouble() ?? 0,
      hoursOvertime: (json['hoursOvertime'] as num?)?.toDouble() ?? 0,
    );
  }
}
