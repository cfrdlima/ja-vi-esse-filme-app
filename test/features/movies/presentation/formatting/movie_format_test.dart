import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/core/l10n/app_locale.dart';
import 'package:ja_vi_esse_filme/features/movies/presentation/formatting/movie_format.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(AppLocale.locale);

  test('deve mostrar horas e minutos', () {
    expect(formatRuntime(l10n, const Duration(minutes: 135)), '2 h 15 min');
  });

  test('deve mostrar só os minutos abaixo de uma hora', () {
    expect(formatRuntime(l10n, const Duration(minutes: 45)), '45 min');
  });

  test('deve mostrar só as horas quando não sobram minutos', () {
    expect(formatRuntime(l10n, const Duration(minutes: 120)), '2 h');
  });
}
