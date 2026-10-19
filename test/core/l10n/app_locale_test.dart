import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

void main() {
  test('o catálogo deve suportar o locale do app', () {
    expect(AppLocalizations.delegate.isSupported(AppLocale.locale), isTrue);
  });

  test('deve carregar o catálogo no locale do app', () {
    expect(() => lookupAppLocalizations(AppLocale.locale), returnsNormally);
  });
}
