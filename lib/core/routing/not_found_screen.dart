import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme_tokens.dart';

/// Destino de qualquer rota que o router não conhece.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({required this.onGoHome, super.key});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.notFoundTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.lg),
                FilledButton(
                  onPressed: onGoHome,
                  child: Text(l10n.notFoundGoHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
