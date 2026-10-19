import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Tela provisória das abas enquanto as features da Fase 1 não chegam.
/// Não tem os 4 estados porque não carrega nada.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          AppLocalizations.of(context).comingSoon,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
