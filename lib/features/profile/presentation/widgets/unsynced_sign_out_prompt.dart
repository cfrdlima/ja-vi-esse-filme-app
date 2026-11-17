import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Aviso no lugar do "Sair" quando sobram marcas sem chegar ao servidor:
/// sair apaga essas marcas (sessão 022, override `perfil.md`).
class UnsyncedSignOutPrompt extends StatelessWidget {
  const UnsyncedSignOutPrompt({
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nó próprio: fundido ao bloco, o anúncio leria a conta inteira.
        Semantics(
          container: true,
          liveRegion: true,
          child: Text(
            l10n.profileUnsyncedWarning,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        SizedBox(height: spacing.md),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            FilledButton(
              onPressed: onCancel,
              child: Text(l10n.profileStaySignedIn),
            ),
            OutlinedButton(
              onPressed: onConfirm,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.profileSignOutAnyway),
            ),
          ],
        ),
      ],
    );
  }
}
