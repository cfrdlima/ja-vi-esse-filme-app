import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Único ponto de acesso HTTP ao TMDB. Trocar para um proxy (decisão 001) é
/// mudar só a base URL e os headers montados aqui.
class TmdbClient {
  TmdbClient({required http.Client httpClient, required AppConfig config})
    : _httpClient = httpClient,
      _config = config;

  final http.Client _httpClient;
  final AppConfig _config;

  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final base = _config.tmdbBaseUrl;
    final url = base.replace(
      path: '${base.path}/$path',
      queryParameters: {...query, 'language': 'pt-BR'},
    );
    final response = await _httpClient.get(
      url,
      headers: {'Authorization': 'Bearer ${_config.tmdbReadToken}'},
    );
    return jsonDecode(response.body) as Map<String, Object?>;
  }
}
