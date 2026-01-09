import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart' show ApiException;

class PlanService {
  PlanService({http.Client? client, String baseUrl = _defaultBaseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const _defaultBaseUrl = 'https://api.forcivil.com';

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<List<PlanPhase>> fetchStructure({
    required String token,
    required int projectId,
  }) async {
    final response = await _client.get(
      _uri('/plan/structure'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Project-Id': projectId.toString(),
        'Accept': 'application/json',
      },
    );

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode != 200) {
      final message = body is Map<String, dynamic> ? body['message'] : null;
      throw ApiException(
        message?.toString() ?? 'Error al obtener la estructura del plan',
        statusCode: response.statusCode,
      );
    }

    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw ApiException(body?['message']?.toString() ?? 'Respuesta inválida');
    }

    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PlanPhase.fromJson)
        .toList();
  }
}

class PlanPhase {
  PlanPhase({
    required this.phaseId,
    required this.phaseName,
    required this.partidas,
  });

  final int phaseId;
  final String phaseName;
  final List<PlanPartida> partidas;

  factory PlanPhase.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> _mapList(dynamic data) =>
        data is List<dynamic>
            ? data.whereType<Map<String, dynamic>>().toList()
            : const [];

    final partidasJson = <Map<String, dynamic>>[
      ..._mapList(json['partidas']),
      ..._mapList(json['children']),
    ];
    return PlanPhase(
      phaseId: json['phaseId'] as int? ?? json['id'] as int? ?? 0,
      phaseName: json['phaseName']?.toString() ??
          json['name']?.toString() ??
          json['phaseCode']?.toString() ??
          'Fase',
      partidas: partidasJson.map(PlanPartida.fromJson).toList(),
    );
  }
}

class PlanPartida {
  PlanPartida({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.metric,
    required this.children,
    this.leaf = true,
  });

  final int id;
  final String code;
  final String name;
  final String? unit;
  final double? metric;
  final List<PlanPartida> children;
  final bool leaf;

  factory PlanPartida.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> _mapList(dynamic data) =>
        data is List<dynamic>
            ? data.whereType<Map<String, dynamic>>().toList()
            : const [];

    final childNodes = <Map<String, dynamic>>[
      ..._mapList(json['children']),
      ..._mapList(json['partidas']),
    ];

    final dynamic idValue = json['id'] ?? json['partidaId'];
    final codeValue = json['code'] ?? json['partidaCode'] ?? json['codePc'];
    final nameValue = json['name'] ?? json['partidaName'];
    final unitValue = json['unit'] ?? json['unitName'];
    final metricValue = json['metric'] ?? json['plannedHh'];

    return PlanPartida(
      id: (idValue is int) ? idValue : int.tryParse(idValue?.toString() ?? '0') ?? 0,
      code: codeValue?.toString() ?? '',
      name: nameValue?.toString() ?? '',
      unit: unitValue?.toString(),
      metric: (metricValue as num?)?.toDouble(),
      children: childNodes.map(PlanPartida.fromJson).toList(),
      leaf: json['leaf'] as bool? ?? childNodes.isEmpty,
    );
  }
}
