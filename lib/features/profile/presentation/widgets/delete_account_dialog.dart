import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Confirmação antes de excluir a conta, que não tem volta (override
/// `perfil.md`). Fecha com `true` só no "Excluir conta"; o "Cancelar" e o
/// voltar do Android fecham sem resposta.
class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  /// Abre o diálogo e diz se a pessoa confirmou.
  static Future<bool> confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const DeleteAccountDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.deleteAccountDialogTitle),
      // Com fonte grande, o texto rola dentro do diálogo.
      content: SingleChildScrollView(child: Text(l10n.deleteAccountDialogBody)),
      actions: [
        // A ação segura vem primeiro na ordem de foco.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.deleteAccountDialogCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.profileDeleteAccount),
        ),
      ],
    );
  }
}
