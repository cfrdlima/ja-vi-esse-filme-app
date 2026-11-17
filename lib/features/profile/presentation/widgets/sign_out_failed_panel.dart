import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/widgets/retry_button.dart';

/// Bloco da conta quando o logout falha. Sem o nome nem o e-mail: a sessão
/// pode já ter fechado (o `SignedOut` chega antes da falha), e a tela não
/// tem como saber de quem era. Tentar de novo é sair outra vez.
class SignOutFailedPanel extends StatelessWidget {
  const SignOutFailedPanel({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: spacing.md),
        RetryButton.filled(onPressed: onRetry),
      ],
    );
  }
}
