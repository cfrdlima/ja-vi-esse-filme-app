import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Bloco da conta logada: nome, e-mail e a ação de sair (override
/// `perfil.md`).
class SignedInPanel extends StatelessWidget {
  const SignedInPanel({required this.user, required this.action, super.key});

  final AppUser user;

  /// O "Sair" ou, depois de uma falha no logout, o "Tentar de novo".
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName ?? l10n.profileUnnamedAccount,
          style: theme.textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (user.email case final email?)
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: spacing.lg),
        action,
      ],
    );
  }
}
