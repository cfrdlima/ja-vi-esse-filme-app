import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Confirmação antes de tirar o Assistido de um filme com nota ou dia, que
/// saem junto (decisão 018, override `detalhes.md`). Fecha com `true` só no
/// "Tirar"; o "Cancelar" e o voltar do Android fecham sem resposta.
class UnwatchDialog extends StatelessWidget {
  const UnwatchDialog({super.key});

  /// Abre o diálogo e diz se a pessoa confirmou.
  static Future<bool> confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const UnwatchDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.unwatchDialogTitle),
      // Com fonte grande, o texto rola dentro do diálogo.
      content: SingleChildScrollView(child: Text(l10n.unwatchDialogBody)),
      actions: [
        // A ação segura vem primeiro na ordem de foco.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.unwatchDialogCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.unwatchDialogConfirm),
        ),
      ],
    );
  }
}
