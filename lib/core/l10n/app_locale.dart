import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Idioma do app, montado em um ponto só para o `main.dart` e os testes.
/// Fixo em pt-BR, qualquer que seja o idioma do aparelho (decisão 004).
abstract final class AppLocale {
  static const locale = Locale('pt', 'BR');
  // Não é `AppLocalizations.supportedLocales` (`[pt]`, do `@@locale` do ARB):
  // com ele, a resolução devolveria `pt`, e o `Localizations.localeOf` e o
  // `intl` perderiam a região. O delegate do catálogo compara só o idioma, por
  // isso aceita `pt_BR`.
  static const supportedLocales = [locale];
  static const delegates = AppLocalizations.localizationsDelegates;
}
