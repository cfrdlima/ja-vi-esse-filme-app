import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/list_name.dart';

void main() {
  Matcher throwsIssue(ListNameIssue issue) => throwsA(
    isA<InvalidListNameException>().having((e) => e.issue, 'issue', issue),
  );

  group('ListName', () {
    test('deve tirar os espaços das pontas', () {
      expect(ListName('  Terror  ').value, 'Terror');
    });

    test('deve aceitar o nome com 50 caracteres', () {
      expect(ListName('a' * 50).value, 'a' * 50);
    });

    test('deve medir o nome depois de tirar os espaços', () {
      expect(ListName('  ${'a' * 50} ').value, 'a' * 50);
    });

    test('deve recusar o nome vazio', () {
      expect(() => ListName(''), throwsIssue(ListNameIssue.empty));
    });

    test('deve recusar o nome só com espaços', () {
      expect(() => ListName('   '), throwsIssue(ListNameIssue.empty));
    });

    test('deve recusar o nome com mais de 50 caracteres', () {
      expect(() => ListName('a' * 51), throwsIssue(ListNameIssue.tooLong));
    });

    // As regras do Firestore contam unidades UTF-16 (decisão 019).
    test('deve aceitar 25 emojis, que contam 50', () {
      expect(ListName('😀' * 25).value, '😀' * 25);
    });

    test('deve recusar 26 emojis, que contam 52', () {
      expect(() => ListName('😀' * 26), throwsIssue(ListNameIssue.tooLong));
    });

    for (final (label, raw) in [
      ('a quebra de linha', 'Ter\nror'),
      ('o tab', 'Ter\trror'),
      ('o caractere nulo', 'Ter\u0000ror'),
      ('o DEL', 'Ter\u007Fror'),
      ('o controle C1', 'Ter\u0085ror'),
    ]) {
      test('deve recusar $label no meio do nome', () {
        expect(
          () => ListName(raw),
          throwsIssue(ListNameIssue.controlCharacter),
        );
      });
    }

    test('deve ser igual a outro com o mesmo nome', () {
      expect(ListName('Terror'), ListName(' Terror'));
    });
  });
}
