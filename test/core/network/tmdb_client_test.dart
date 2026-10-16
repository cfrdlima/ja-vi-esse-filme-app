import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ja_vi_esse_filme/core/config/app_config.dart';
import 'package:ja_vi_esse_filme/core/error/failures.dart';
import 'package:ja_vi_esse_filme/core/network/tmdb_client.dart';

import '../../helpers/fixtures.dart';

void main() {
  final config = AppConfig(
    tmdbReadToken: 'token-de-teste',
    tmdbBaseUrl: Uri.parse('https://api.themoviedb.org/3'),
  );

  late http.Request captured;

  TmdbClient clientRespondingWith(
    String body,
    int status, {
    Map<String, String> headers = const {},
  }) {
    return TmdbClient(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(body, status, headers: headers);
      }),
      config: config,
    );
  }

  group('requisição', () {
    test('deve montar a URL com base, path, query e language=pt-BR', () async {
      final client = clientRespondingWith(
        readFixture('tmdb_authentication_ok.json'),
        200,
      );

      await client.get('search/movie', query: {'query': 'Matrix'});

      expect(
        captured.url,
        Uri.parse(
          'https://api.themoviedb.org/3/search/movie?query=Matrix&language=pt-BR',
        ),
      );
    });

    test('deve autenticar com o token de leitura no header Bearer', () async {
      final client = clientRespondingWith(
        readFixture('tmdb_authentication_ok.json'),
        200,
      );

      await client.get('authentication');

      expect(captured.headers['Authorization'], 'Bearer token-de-teste');
    });
  });

  group('resposta 200', () {
    test('deve devolver o JSON decodificado', () async {
      final client = clientRespondingWith(
        readFixture('tmdb_authentication_ok.json'),
        200,
      );

      final json = await client.get('authentication');

      expect(json['status_message'], 'Success.');
    });

    test(
      'deve decodificar texto acentuado mesmo sem charset no header',
      () async {
        final client = TmdbClient(
          httpClient: MockClient(
            (_) async => http.Response.bytes(
              utf8.encode('{"title": "Cidade de Deus — São Paulo"}'),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
          config: config,
        );

        final json = await client.get('movie/598');

        expect(json['title'], 'Cidade de Deus — São Paulo');
      },
    );
  });

  group('status de erro', () {
    test('deve lançar UnauthorizedFailure no 401', () {
      final client = clientRespondingWith(
        readFixture('tmdb_error_401.json'),
        401,
      );

      expect(client.get('movie/11'), throwsA(isA<UnauthorizedFailure>()));
    });

    test('deve lançar NotFoundFailure no 404', () {
      final client = clientRespondingWith(
        readFixture('tmdb_error_404.json'),
        404,
      );

      expect(client.get('movie/0'), throwsA(isA<NotFoundFailure>()));
    });

    test('deve lançar RateLimitFailure no 429', () {
      final client = clientRespondingWith('', 429);

      expect(client.get('movie/11'), throwsA(isA<RateLimitFailure>()));
    });

    test('deve ler o Retry-After do 429 quando ele vier', () {
      final client = clientRespondingWith(
        '',
        429,
        headers: {'retry-after': '3'},
      );

      expect(
        client.get('movie/11'),
        throwsA(
          isA<RateLimitFailure>().having(
            (f) => f.retryAfter,
            'retryAfter',
            const Duration(seconds: 3),
          ),
        ),
      );
    });

    test('deve lançar ServerFailure com o status no 5xx', () {
      final client = clientRespondingWith('', 503);

      expect(
        client.get('movie/11'),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('deve lançar UnexpectedFailure em outro status de erro', () {
      final client = clientRespondingWith('', 422);

      expect(client.get('movie/11'), throwsA(isA<UnexpectedFailure>()));
    });
  });

  group('falha de rede', () {
    TmdbClient clientThrowing(Object error) {
      return TmdbClient(
        httpClient: MockClient((_) async => throw error),
        config: config,
      );
    }

    test('deve lançar NetworkFailure quando o http lança ClientException', () {
      final client = clientThrowing(
        http.ClientException(
          'Connection closed',
          Uri.parse('https://api.themoviedb.org/3/movie/11'),
        ),
      );

      expect(client.get('movie/11'), throwsA(isA<NetworkFailure>()));
    });

    test('deve lançar NetworkFailure quando não há conexão', () {
      final client = clientThrowing(
        const SocketException('Failed host lookup'),
      );

      expect(client.get('movie/11'), throwsA(isA<NetworkFailure>()));
    });

    test('deve lançar NetworkFailure quando a resposta demora demais', () {
      final client = TmdbClient(
        httpClient: MockClient((_) => Completer<http.Response>().future),
        config: config,
        timeout: const Duration(milliseconds: 1),
      );

      expect(client.get('movie/11'), throwsA(isA<NetworkFailure>()));
    });

    test('não deve levar a URL da requisição na falha', () async {
      final client = clientThrowing(
        http.ClientException(
          'Connection closed',
          Uri.parse('https://api.themoviedb.org/3/account?session_id=segredo'),
        ),
      );

      final failure = await client
          .get('account')
          .then<Object?>((_) => null, onError: (Object error) => error);

      expect(failure.toString(), isNot(contains('segredo')));
    });
  });
}
