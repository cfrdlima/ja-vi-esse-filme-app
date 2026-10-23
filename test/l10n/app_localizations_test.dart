import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

/// Formatos de número e data que o ARB entrega ao `intl`.
void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  // No app, o delegate do Material carrega os símbolos de data do pt.
  setUpAll(() => initializeDateFormatting(l10n.localeName));

  test('deve mostrar a nota com uma casa decimal e vírgula', () {
    expect(l10n.rating(7.84), '7,8');
  });

  test('deve manter a casa decimal na nota inteira', () {
    expect(l10n.rating(8), '8,0');
  });

  test('deve ler a nota com a escala para o leitor de tela', () {
    expect(l10n.ratingSemantics(7.84), 'Nota 7,8 de 10');
  });

  test('deve mostrar a data de lançamento no formato curto do pt-BR', () {
    expect(l10n.releaseDate(DateTime(2024, 2, 7)), '07/02/2024');
  });
}
