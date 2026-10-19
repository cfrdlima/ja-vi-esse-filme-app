import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_vi_esse_filme/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

  final cases = <(String, String Function(AppLocalizations), String)>[
    ('aba Descobrir', (l) => l.tabDiscover, 'Descobrir'),
    ('aba Buscar', (l) => l.tabSearch, 'Buscar'),
    ('aba Estante', (l) => l.tabShelf, 'Estante'),
    ('aba Perfil', (l) => l.tabProfile, 'Perfil'),
    ('título da estante', (l) => l.shelfTitle, 'Minha estante'),
    ('aviso do placeholder', (l) => l.comingSoon, 'Em breve'),
    (
      'título da página não encontrada',
      (l) => l.notFoundTitle,
      'Página não encontrada',
    ),
    (
      'ação da página não encontrada',
      (l) => l.notFoundGoHome,
      'Ir para Descobrir',
    ),
  ];

  for (final (name, read, expected) in cases) {
    test('o catálogo pt-BR deve ter o texto da $name', () {
      expect(read(l10n), expected);
    });
  }
}
