import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../error/failures.dart';

/// Único ponto de acesso HTTP ao TMDB. Trocar para um proxy (decisão 001) é
/// mudar só a base URL e os headers montados aqui.
class TmdbClient {
  TmdbClient({
    required this._httpClient,
    required this._config,
    this._timeout = const Duration(seconds: 15),
  });

  final http.Client _httpClient;
  final AppConfig _config;
  final Duration _timeout;

  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final response = await _send(_buildUrl(path, query));
    _throwOnError(response);
    return _decodeObject(response.bodyBytes);
  }

  /// [path] é relativo à base e fixo no código; entrada do usuário vai só na
  /// [query], que o `Uri` codifica.
  Uri _buildUrl(String path, Map<String, String> query) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final unsafe = segments.any(
      (s) => s == '.' || s == '..' || s.contains('?') || s.contains('#'),
    );
    if (unsafe) throw ArgumentError.value(path, 'path', 'path inseguro');
    final base = _config.tmdbBaseUrl;
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        ...segments,
      ],
      queryParameters: {'language': 'pt-BR', ...query},
    );
  }

  // As exceções do http e do dart:io carregam a URI, que pode ter segredo.
  // Viram NetworkFailure sem nada da requisição.
  Future<http.Response> _send(Uri url) async {
    try {
      return await _httpClient
          .get(
            url,
            headers: {'Authorization': 'Bearer ${_config.tmdbReadToken}'},
          )
          .timeout(_timeout);
    } on http.ClientException {
      throw const NetworkFailure();
    } on IOException {
      // SocketException (sem rede) e TlsException (certificado) caem aqui.
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    } on Exception {
      // A mensagem original pode ter a URI; não é repassada. Error (bug de
      // programação) não é capturado de propósito.
      throw const UnexpectedFailure('falha inesperada no envio');
    }
  }

  void _throwOnError(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;
    throw switch (status) {
      401 => const UnauthorizedFailure(),
      404 => const NotFoundFailure(),
      429 => RateLimitFailure(retryAfter: _retryAfter(response)),
      >= 500 && < 600 => ServerFailure(status),
      _ => UnexpectedFailure('status $status'),
    };
  }

  // O TMDB responde em UTF-8; decodificar os bytes aqui mantém o charset
  // inválido dentro do mesmo tratamento de corpo inválido.
  Map<String, Object?> _decodeObject(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map<String, Object?>) return json;
      throw const UnexpectedFailure('o JSON não é um objeto');
    } on FormatException {
      throw const UnexpectedFailure('o corpo não é JSON em UTF-8');
    }
  }

  Duration? _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
