import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/domain/entities/watched_on.dart';

void main() {
  group('WatchedOn', () {
    test('deve aceitar o primeiro ano do cinema', () {
      expect(WatchedOn(year: 1888, month: 1, day: 1).year, 1888);
    });

    test('deve recusar o ano antes do cinema', () {
      expect(
        () => WatchedOn(year: 1887, month: 12, day: 31),
        throwsArgumentError,
      );
    });

    test('deve recusar ano com mais de quatro dígitos', () {
      expect(
        () => WatchedOn(year: 10000, month: 1, day: 1),
        throwsArgumentError,
      );
    });

    test('deve aceitar 29 de fevereiro em ano bissexto', () {
      expect(WatchedOn(year: 2028, month: 2, day: 29).day, 29);
    });

    test('deve recusar 29 de fevereiro fora do ano bissexto', () {
      expect(
        () => WatchedOn(year: 2026, month: 2, day: 29),
        throwsArgumentError,
      );
    });

    test('deve recusar o mês 13', () {
      expect(
        () => WatchedOn(year: 2026, month: 13, day: 1),
        throwsArgumentError,
      );
    });

    test('deve recusar o dia zero', () {
      expect(
        () => WatchedOn(year: 2026, month: 11, day: 0),
        throwsArgumentError,
      );
    });

    // O watchedAt vem em UTC; 01:00 UTC ainda é o dia anterior em Brasília.
    test('deve pegar o dia local de um momento', () {
      final moment = DateTime.utc(2026, 11, 18, 1).toLocal();

      expect(
        WatchedOn.fromLocal(moment),
        WatchedOn(year: moment.year, month: moment.month, day: moment.day),
      );
    });

    test('deve dizer que um dia vem depois do outro', () {
      final today = WatchedOn(year: 2026, month: 11, day: 18);

      expect(WatchedOn(year: 2026, month: 11, day: 19).isAfter(today), isTrue);
    });

    test('não deve dizer que o mesmo dia vem depois', () {
      final today = WatchedOn(year: 2026, month: 11, day: 18);

      expect(WatchedOn(year: 2026, month: 11, day: 18).isAfter(today), isFalse);
    });

    test('não deve dizer que um ano anterior vem depois', () {
      final today = WatchedOn(year: 2026, month: 1, day: 1);

      expect(WatchedOn(year: 2025, month: 12, day: 31).isAfter(today), isFalse);
    });
  });
}
