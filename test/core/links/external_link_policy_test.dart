import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/links/external_link_policy.dart';

void main() {
  const policy = ExternalLinkPolicy.app;

  test('deve permitir o trailer no YouTube', () {
    final url = Uri.parse('https://www.youtube.com/watch?v=Way9Dexny3w');

    expect(policy.allows(url), isTrue);
  });

  test('deve comparar o host sem diferenciar maiúsculas', () {
    final url = Uri.parse('https://WWW.YouTube.com/watch?v=Way9Dexny3w');

    expect(policy.allows(url), isTrue);
  });

  for (final (reason, link) in [
    ('sem https', 'http://www.youtube.com/watch?v=Way9Dexny3w'),
    ('com outro esquema', 'intent://www.youtube.com/watch?v=Way9Dexny3w'),
    ('de host fora da lista', 'https://example.com/watch?v=Way9Dexny3w'),
    ('de subdomínio do host', 'https://evil.www.youtube.com/watch'),
    ('de host que só termina igual', 'https://notwww.youtube.com/watch'),
    ('de host que só começa igual', 'https://www.youtube.com.evil.com/watch'),
    ('com userInfo', 'https://user@www.youtube.com/watch?v=Way9Dexny3w'),
    ('com porta', 'https://www.youtube.com:8443/watch?v=Way9Dexny3w'),
    ('relativa', '/watch?v=Way9Dexny3w'),
  ]) {
    test('deve recusar a URL $reason', () {
      expect(policy.allows(Uri.parse(link)), isFalse);
    });
  }

  test('não deve compartilhar os hosts com a base URL da API', () {
    final url = Uri.parse('https://api.themoviedb.org/3/movie/1');

    expect(policy.allows(url), isFalse);
  });
}
