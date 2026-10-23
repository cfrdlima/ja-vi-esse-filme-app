import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/movies/domain/entities/search_query.dart';

void main() {
  group('termo', () {
    test('deve aparar os espaços das pontas', () {
      final query = SearchQuery('  matrix  ');

      expect(query.text, 'matrix');
    });

    test('deve juntar espaços repetidos e quebras de linha em um espaço', () {
      final query = SearchQuery('o  poderoso\n\tchefão');

      expect(query.text, 'o poderoso chefão');
    });

    test('deve manter acentos e símbolos como foram digitados', () {
      final query = SearchQuery('Amélie & cia');

      expect(query.text, 'Amélie & cia');
    });
  });

  group('tamanho', () {
    test('deve aceitar o termo com o mínimo de caracteres', () {
      final query = SearchQuery('ab');

      expect(query.text, 'ab');
    });

    test('deve recusar o termo vazio como curto demais', () {
      expect(
        () => SearchQuery(''),
        throwsA(
          isA<InvalidSearchQuery>().having(
            (e) => e.reason,
            'reason',
            InvalidSearchQueryReason.tooShort,
          ),
        ),
      );
    });

    test('deve recusar o termo curto depois de aparado', () {
      expect(
        () => SearchQuery('  a  '),
        throwsA(
          isA<InvalidSearchQuery>().having(
            (e) => e.reason,
            'reason',
            InvalidSearchQueryReason.tooShort,
          ),
        ),
      );
    });

    test('deve aceitar o termo com o máximo de caracteres', () {
      final text = 'a' * SearchQuery.maxLength;

      expect(SearchQuery(text).text, text);
    });

    test('deve recusar o termo acima do máximo como longo demais', () {
      expect(
        () => SearchQuery('a' * (SearchQuery.maxLength + 1)),
        throwsA(
          isA<InvalidSearchQuery>().having(
            (e) => e.reason,
            'reason',
            InvalidSearchQueryReason.tooLong,
          ),
        ),
      );
    });

    test('deve contar o acento combinante como mais um caractere', () {
      // "é" decomposto ("e" + acento combinante) são dois code points; o
      // domínio conta code points, que é o que vai na URL para o TMDB.
      final text = 'e\u0301' * 51;

      expect(
        () => SearchQuery(text),
        throwsA(
          isA<InvalidSearchQuery>().having(
            (e) => e.reason,
            'reason',
            InvalidSearchQueryReason.tooLong,
          ),
        ),
      );
    });

    test('deve contar um emoji como um caractere, e não dois', () {
      final text = '🎬' * SearchQuery.maxLength;

      expect(SearchQuery(text).text, text);
    });

    test('deve ter os limites de 2 e 100 caracteres', () {
      expect((SearchQuery.minLength, SearchQuery.maxLength), (2, 100));
    });
  });

  group('igualdade', () {
    test('deve ser igual a outro termo com o mesmo texto normalizado', () {
      expect(SearchQuery(' matrix '), SearchQuery('matrix'));
    });

    test('deve ter o mesmo hashCode de um termo igual', () {
      expect(SearchQuery(' matrix ').hashCode, SearchQuery('matrix').hashCode);
    });

    test('deve diferenciar maiúsculas, como o texto digitado', () {
      expect(SearchQuery('Matrix'), isNot(SearchQuery('matrix')));
    });
  });

  test('não deve expor o termo no toString', () {
    expect(SearchQuery('segredo').toString(), isNot(contains('segredo')));
  });
}
