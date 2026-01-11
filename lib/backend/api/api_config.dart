import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._({String? baseUrl}) : baseUrl = _normalize(baseUrl);

  static ApiConfig? _instance;
  static ApiConfig get instance => _instance ??= ApiConfig._();

  final String baseUrl;

  static void configure(String url) {
    _instance = ApiConfig._(baseUrl: url);
  }

  static String _normalize(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return 'https://api.forcivil.com';
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Uri uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized');
  }
}

mixin ApiConfigurable {
  @protected
  ApiConfig get apiConfig => ApiConfig.instance;
}
