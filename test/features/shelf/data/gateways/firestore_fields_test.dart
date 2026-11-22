import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/firestore_fields.dart';
import 'package:ja_vi_esse_filme/features/shelf/data/gateways/shelf_gateway.dart';

void main() {
  final now = DateTime.utc(2026, 11, 17, 12);

  group('FirestoreFields.read', () {
    test('deve converter o Timestamp em DateTime UTC', () {
      final at = DateTime.utc(2026, 11, 2);

      final fields = FirestoreFields.read({
        'watchedAt': Timestamp.fromDate(at),
      }, pendingAt: null);

      expect(fields['watchedAt'], at);
    });

    test('deve manter os outros valores como vieram', () {
      final fields = FirestoreFields.read({
        'title': 'Clube da Luta',
      }, pendingAt: null);

      expect(fields['title'], 'Clube da Luta');
    });

    test('deve estimar a data pendente com a hora local', () {
      final fields = FirestoreFields.read({'watchedAt': null}, pendingAt: now);

      expect(fields['watchedAt'], now);
    });

    test('deve manter o null sem escrita pendente', () {
      final fields = FirestoreFields.read({'watchedAt': null}, pendingAt: null);

      expect(fields['watchedAt'], isNull);
    });

    // As horas do mapa lists (decisão 019) ficam um nível abaixo.
    test('deve converter o Timestamp dentro de um mapa', () {
      final at = DateTime.utc(2026, 11, 2);

      final fields = FirestoreFields.read({
        'lists': {'Lst0aBcDeFgHiJkLmNoP': Timestamp.fromDate(at)},
      }, pendingAt: null);

      expect(fields['lists'], {'Lst0aBcDeFgHiJkLmNoP': at});
    });

    test('deve estimar a data pendente dentro de um mapa', () {
      final fields = FirestoreFields.read({
        'lists': {'Lst0aBcDeFgHiJkLmNoP': null},
      }, pendingAt: now);

      expect(fields['lists'], {'Lst0aBcDeFgHiJkLmNoP': now});
    });

    test('deve devolver o mapa vazio sem documento', () {
      expect(FirestoreFields.read(null, pendingAt: null), isEmpty);
    });
  });

  group('FirestoreFields.write', () {
    test('deve repassar o valor do SetField', () {
      final fields = FirestoreFields.write({'title': const SetField('Filme')});

      expect(fields['title'], 'Filme');
    });

    test('deve trocar o ServerTime pelo serverTimestamp do SDK', () {
      final fields = FirestoreFields.write({'cachedAt': const ServerTime()});

      expect(fields['cachedAt'], FieldValue.serverTimestamp());
    });

    test('deve converter os campos de um MapFields', () {
      final fields = FirestoreFields.write({
        'lists': const MapFields({'Lst0aBcDeFgHiJkLmNoP': ServerTime()}),
      });

      expect(fields['lists'], {
        'Lst0aBcDeFgHiJkLmNoP': FieldValue.serverTimestamp(),
      });
    });

    test('deve trocar o DeleteField pelo delete do SDK', () {
      final fields = FirestoreFields.write({'posterPath': const DeleteField()});

      expect(fields['posterPath'], FieldValue.delete());
    });
  });
}
