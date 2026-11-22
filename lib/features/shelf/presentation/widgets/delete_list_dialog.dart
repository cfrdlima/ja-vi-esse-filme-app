import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/movie_list.dart';

/// Confirmação antes de apagar uma lista (override `estante.md`). Fecha com
/// `true` só no "Apagar".
class DeleteListDialog extends StatelessWidget {
  const DeleteListDialog({required this.list, super.key});

  final MovieList list;

  static Future<bool> confirm(BuildContext context, MovieList list) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => DeleteListDialog(list: list),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(l10n.listsDeleteTitle(list.name.value)),
      content: SingleChildScrollView(child: Text(l10n.listsDeleteBody)),
      actions: [
        // A ação segura vem primeiro na ordem de foco.
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.listsCancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.listsDelete),
        ),
      ],
    );
  }
}
