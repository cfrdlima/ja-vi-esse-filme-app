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

  test('deve mascarar bearer em minúsculas', () {
    final text = redactSecrets(r'authorization: bearer abc123');

    expect(text, r'authorization: bearer ***');
  });

  test('deve mascarar BEARER em maiúsculas', () {
    final text = redactSecrets(r'BEARER abc123');

    expect(text, r'BEARER ***');
  });

  test('deve mascarar nome de segredo com outra grafia', () {
    final text = redactSecrets(r'Session_Id=abc&page=2');

    expect(text, r'Session_Id=***&page=2');
  });

  test('deve mascarar guest_session_id na query', () {
    final text = redactSecrets(r'guest_session_id=abc');

    expect(text, r'guest_session_id=***');
  });

  test('deve mascarar guest_session_id em JSON', () {
    final text = redactSecrets(r'{"guest_session_id":"abc"}');

    expect(text, r'{"guest_session_id":"***"}');
  });

  test('deve mascarar access_token da auth v4', () {
    final text = redactSecrets(r'{"access_token":"abc"}');

    expect(text, r'{"access_token":"***"}');
  });

  test('deve mascarar session_id no toString de um Map', () {
    final text = redactSecrets(r'{session_id: abc, page: 1}');

    expect(text, r'{session_id: ***, page: 1}');
  });

  test('deve mascarar session_id codificado na URL', () {
    final text = redactSecrets(r'next=%2Faccount%3Fsession_id%3Dabc');

    expect(text, r'next=%2Faccount%3Fsession_id%3D***');
  });

  test('deve mascarar session_id em JSON escapado', () {
    final text = redactSecrets(r'{\"session_id\": \"abc\"}');

    expect(text, r'{\"session_id\": \"***\"}');
  });

  test('deve mascarar o valor inteiro mesmo com aspas escapadas', () {
    final text = redactSecrets(r'{"session_id":"a\"bc"}');

    expect(text, r'{"session_id":"***"}');
  });

  group('tokens do Firebase e do Google', () {
    test('deve mascarar idToken em JSON', () {
      final text = redactSecrets('{"idToken": "abc.def.ghi", "ok": true}');

      expect(text, '{"idToken": "***", "ok": true}');
    });

    test('deve mascarar refreshToken em JSON escapado', () {
      final text = redactSecrets(r'{\"refreshToken\": \"AMf-vB\"}');

      expect(text, r'{\"refreshToken\": \"***\"}');
    });

    test('deve mascarar accessToken no toString de um Map', () {
      final text = redactSecrets('{accessToken: tok-1, providerId: google}');

      expect(text, '{accessToken: ***, providerId: google}');
    });

    test('deve mascarar id_token na query', () {
      final text = redactSecrets('/callback?id_token=abc&state=1');

      expect(text, '/callback?id_token=***&state=1');
    });

    test('deve mascarar JWT solto no texto', () {
      final text = redactSecrets(
        'token inválido: eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIxIn0.c2ln-_x fim',
      );

      expect(text, 'token inválido: *** fim');
    });

    test('deve mascarar access token do Google solto no texto', () {
      final text = redactSecrets('falhou com ya29.a0AfH6SM-x_y9 agora');

      expect(text, 'falhou com *** agora');
    });
  });

  test('deve manter texto sem segredo como está', () {
    final text = redactSecrets('Falha de rede ao buscar filmes');

    expect(text, 'Falha de rede ao buscar filmes');
  });
}
