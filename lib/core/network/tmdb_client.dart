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
    final base = _config.tmdbBaseUrl;
    final url = base.replace(
      path: '${base.path}/$path',
      queryParameters: {...query, 'language': 'pt-BR'},
    );
    final response = await _send(url);
    _throwOnError(response);
    return jsonDecode(response.body) as Map<String, Object?>;
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
    } on SocketException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
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

  Duration? _retryAfter(http.Response response) {
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
