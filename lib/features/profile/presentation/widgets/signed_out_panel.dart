import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Bloco da conta sem login: o convite a entrar, o que a conta guarda e a
/// ação de entrar (override `perfil.md`). A [action] é o botão do Google,
/// pronto ou entrando, conforme o estado da sessão.
class SignedOutPanel extends StatelessWidget {
  const SignedOutPanel({required this.action, super.key});

  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Icon(
          Icons.account_circle_outlined,
          size: AppSizes.stateIcon,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: spacing.md),
        Text(
          l10n.profileSignedOutTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.sm),
        Text(
          l10n.profileSignedOutBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.lg),
        action,
      ],
    );
  }
}
