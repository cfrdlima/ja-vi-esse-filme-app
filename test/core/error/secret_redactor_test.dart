import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/error/secret_redactor.dart';

void main() {
  test('deve mascarar api_key na query', () {
    final text = redactSecrets('GET https://x.org/3/movie/11?api_key=abc123');

    expect(text, 'GET https://x.org/3/movie/11?api_key=***');
  });

  test('deve mascarar session_id sem apagar os outros parâmetros', () {
    final text = redactSecrets('/account?session_id=s3cr3t&page=2');

    expect(text, '/account?session_id=***&page=2');
  });

  test('deve mascarar request_token', () {
    final text = redactSecrets('request_token=tok-9 aprovado');

    expect(text, 'request_token=*** aprovado');
  });

  test('deve mascarar o token do header Bearer', () {
    final text = redactSecrets('Authorization: Bearer eyJhbGciOi.x-y_z');

    expect(text, 'Authorization: Bearer ***');
  });

  test('deve mascarar session_id em JSON, como na resposta da sessão', () {
    final text = redactSecrets('{"success":true,"session_id": "79191836"}');

    expect(text, '{"success":true,"session_id": "***"}');
  });

  test('deve manter texto sem segredo como está', () {
    final text = redactSecrets('Falha de rede ao buscar filmes');

    expect(text, 'Falha de rede ao buscar filmes');
  });
}
