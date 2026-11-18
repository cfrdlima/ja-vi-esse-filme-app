import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/failure_message.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/state/session_notifier.dart';
import '../../../auth/presentation/state/session_state.dart';
import 'delete_account_dialog.dart';

/// O "Excluir conta" no fim do Perfil, separado das ações comuns (override
/// `perfil.md`). Só aparece com a conta aberta.
class DeleteAccountSection extends StatelessWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<SessionNotifier, SessionState>(
      (notifier) => notifier.state,
    );
    final l10n = AppLocalizations.of(context);
    final notifier = context.read<SessionNotifier>();
    final entry = switch (state) {
      SessionSignedIn() => _DeleteAccountEntry(
        label: l10n.profileDeleteAccount,
        onPressed: () => unawaited(_confirmAndDelete(context, notifier)),
      ),
      SessionDeletingAccount() => _DeleteAccountEntry.deleting(
        label: l10n.profileDeletingAccount,
      ),
      // A pessoa já confirmou: tentar de novo exclui direto.
      SessionDeleteAccountFailed(:final failure) => _DeleteAccountEntry(
        label: l10n.profileDeleteAccountRetry,
        error: failureMessage(l10n, failure),
        onPressed: () => unawaited(notifier.deleteAccount()),
      ),
      _ => null,
    };
    if (entry == null) return const SizedBox.shrink();
    final spacing = Theme.of(context).extension<AppThemeTokens>()!.spacing;
    return Column(
      children: [
        const Divider(),
        SizedBox(height: spacing.lg),
        Align(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readableWidth),
            // Na largura de leitura toda, como o bloco da conta, para o
            // botão ficar alinhado à esquerda com o "Sair".
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: SizedBox(width: double.infinity, child: entry),
            ),
          ),
        ),
        SizedBox(height: spacing.lg),
      ],
    );
  }

  static Future<void> _confirmAndDelete(
    BuildContext context,
    SessionNotifier notifier,
  ) async {
    if (await DeleteAccountDialog.confirm(context)) {
      await notifier.deleteAccount();
    }
  }
}

class _DeleteAccountEntry extends StatelessWidget {
  const _DeleteAccountEntry({
    required this.label,
    required VoidCallback this.onPressed,
    this.error,
  });

  const _DeleteAccountEntry.deleting({required this.label})
    : onPressed = null,
      error = null;

  final String label;

  /// `null` só no [_DeleteAccountEntry.deleting].
  final VoidCallback? onPressed;

  /// Mensagem da exclusão que falhou, acima do botão.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppThemeTokens>()!.spacing;
    final l10n = AppLocalizations.of(context);
    final deleting = onPressed == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (error case final error?) ...[
          // Num nó próprio, para o leitor anunciar só a mensagem.
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
        ],
        Semantics(
          liveRegion: deleting,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: onPressed,
            icon: deleting
                ? const SizedBox.square(
                    dimension: AppSizes.buttonProgress,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.buttonProgressStroke,
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(label),
          ),
        ),
        Text(
          l10n.profileDeleteAccountHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
