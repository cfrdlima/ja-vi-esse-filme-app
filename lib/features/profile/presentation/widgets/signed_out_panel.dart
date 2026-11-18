import 'package:flutter/material.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Bloco da conta sem login: o convite a entrar, o que a conta guarda e a
/// ação de entrar (override `perfil.md`). A [action] é o botão do Google,
/// pronto ou entrando, conforme o estado da sessão.
class SignedOutPanel extends StatelessWidget {
  const SignedOutPanel({
    required this.action,
    this.error,
    this.notice,
    super.key,
  });

  final Widget action;

  /// Mensagem da falha no login, acima do botão. O próprio botão serve de
  /// "tentar de novo", porque a ação é a mesma.
  final String? error;

  /// Aviso no topo do bloco, como o da conta que acabou de ser excluída.
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (notice case final notice?) ...[
          // Num nó próprio, para o leitor anunciar só o aviso.
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              notice,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: spacing.lg),
        ],
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
        if (error case final error?) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: spacing.md),
        ],
        action,
      ],
    );
  }
}
